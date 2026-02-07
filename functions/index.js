const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

admin.initializeApp();

function audienceRolesForEvent(type) {
    switch (type) {
        case "transfer_created":
            return ["loader"];
        case "transfer_picked":
            return ["storekeeper"];
        case "transfer_checking":
            return ["storekeeper"];
        case "transfer_done":
            return ["admin", "storekeeper", "loader"]; // staff
        case "barcode_bound":
            return ["storekeeper", "admin"];
        default:
            return ["admin", "storekeeper", "loader"];
    }
}

function buildNotification(type, transferId) {
    switch (type) {
        case "transfer_created":
            return { title: "New transfer", body: `Transfer ${transferId} ready to pick` };
        case "transfer_picked":
            return { title: "Transfer picked", body: `Transfer ${transferId} picked` };
        case "transfer_checking":
            return { title: "Checking started", body: `Transfer ${transferId} checking` };
        case "transfer_done":
            return { title: "Transfer done", body: `Transfer ${transferId} finished` };
        case "barcode_bound":
            return { title: "Barcode bound", body: "Barcode bound to product" };
        default:
            return { title: "Update", body: "New event" };
    }
}

function chunk(arr, size) {
    const out = [];
    for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
    return out;
}

exports.onTransferEventCreated = onDocumentCreated(
    "transfers/{transferId}/events/{eventId}",
    async (event) => {
        const snap = event.data;
        if (!snap) return;

        const data = snap.data();
        const type = data.type;
        const transferId = data.transferId || event.params.transferId;

        const roles = audienceRolesForEvent(type);
        const { title, body } = buildNotification(type, transferId);

        const usersSnap = await admin.firestore()
            .collection("users")
            .where("isActive", "==", true)
            .where("role", "in", roles)
            .get();

        const tokenToUserRef = new Map();
        const tokens = [];

        for (const doc of usersSnap.docs) {
            const u = doc.data();
            const fcmTokens = u.fcmTokens || {};
            for (const t of Object.keys(fcmTokens)) {
                if (!tokenToUserRef.has(t)) {
                    tokenToUserRef.set(t, doc.ref);
                    tokens.push(t);
                }
            }
        }

        if (tokens.length === 0) return;

        const payload = {
            notification: { title, body },
            data: {
                type: String(type || ""),
                transferId: String(transferId || ""),
            },
        };

        const batches = chunk(tokens, 500);
        for (const batchTokens of batches) {
            const resp = await admin.messaging().sendEachForMulticast({
                tokens: batchTokens,
                ...payload,
            });

            const deletesByUserPath = new Map(); // path -> { ref, tokens[] }

            resp.responses.forEach((r, idx) => {
                if (r.success) return;

                const err = r.error;
                if (!err) return;

                const code = err.code || "";
                if (
                    code === "messaging/registration-token-not-registered" ||
                    code === "messaging/invalid-registration-token"
                ) {
                    const badToken = batchTokens[idx];
                    const userRef = tokenToUserRef.get(badToken);
                    if (!userRef) return;

                    if (!deletesByUserPath.has(userRef.path)) {
                        deletesByUserPath.set(userRef.path, { ref: userRef, tokens: [] });
                    }
                    deletesByUserPath.get(userRef.path).tokens.push(badToken);
                }
            });

            const writes = [];
            for (const entry of deletesByUserPath.values()) {
                const update = {};
                for (const t of entry.tokens) {
                    update[`fcmTokens.${t}`] = admin.firestore.FieldValue.delete();
                }
                writes.push(entry.ref.update(update));
            }
            await Promise.all(writes);
        }
    }
);
