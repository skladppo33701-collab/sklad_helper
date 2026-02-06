users/{uid}

products/{article}
    name
    category
    barcode
    updatedAt

barcode_index/{barcode}
    article

transfers/{transferId}
    status
    createdBy
    timestamps

transfers/{id}/lines/{lineId}
    article
    qtyPlanned
    qtyPicked
    lock:
        userId
        expiresAt
    status

transfers/{id}/events/{eventId}
    type
    userId
    timestamp
