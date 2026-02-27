ClientState = ClientState or {}
ClientState.equipment = { slots = {} }
ClientState.stats = {}
ClientState.activeSetBonuses = {}
ClientState.activePassives = {}
ClientState.isUiOpen = false
ClientState.lastHealth = nil
ClientState.ignoreSelfHeal = false

ClientState.wearQueue = {}
ClientState.wearQueueHits = 0
ClientState.wearQueueDirty = false

ClientState.nuiReady = false

ClientState.nuiDirty = false
ClientState.nuiDirtyAt = 0
ClientState.nuiPendingExtra = nil
ClientState.lastNuiSentAt = 0
