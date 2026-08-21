import QtQuick

QtObject {
    id: listModelUtils

    function syncListModel(listModel, sourceArray, keyProp, maxLimit) {
        if (!sourceArray || sourceArray.length === 0) {
            listModel.clear();
            return;
        }

        var limit = maxLimit > 0 ? Math.min(sourceArray.length, maxLimit) : sourceArray.length;

        if (listModel.count === 0) {
            for (var a = 0; a < limit; a++) {
                var itm = sourceArray[a];
                listModel.append(typeof itm === "object" ? itm : { "entryData": itm });
            }
            return;
        }

        // 1. Build map of target keys for fast lookup
        var targetMap = {};
        for (var t = 0; t < limit; t++) {
            var val = sourceArray[t];
            var kVal = (typeof val === "object" && keyProp) ? val[keyProp] : val;
            targetMap[kVal] = true;
        }

        // 2. Remove items not present in target array first
        for (var r = listModel.count - 1; r >= 0; r--) {
            var curr = listModel.get(r);
            var currKey = (curr && keyProp && curr[keyProp] !== undefined) ? curr[keyProp] : (curr ? curr.entryData : curr);
            if (!curr || !targetMap[currKey]) {
                listModel.remove(r);
            }
        }

        // 3. Reorder existing items and insert new items at the correct position
        for (var j = 0; j < limit; j++) {
            var targetItem = sourceArray[j];
            var targetKeyVal = (typeof targetItem === "object" && keyProp) ? targetItem[keyProp] : targetItem;

            if (j < listModel.count) {
                var modelItem = listModel.get(j);
                var modelKeyVal = (modelItem && keyProp && modelItem[keyProp] !== undefined) ? modelItem[keyProp] : (modelItem ? modelItem.entryData : modelItem);

                if (modelKeyVal === targetKeyVal) {
                    continue; // Already at the right index
                }

                // Look ahead to see if it's already in the model further down
                var foundIdx = -1;
                for (var k = j + 1; k < listModel.count; k++) {
                    var lookItem = listModel.get(k);
                    var lookKeyVal = (lookItem && keyProp && lookItem[keyProp] !== undefined) ? lookItem[keyProp] : (lookItem ? lookItem.entryData : lookItem);
                    if (lookKeyVal === targetKeyVal) {
                        foundIdx = k;
                        break;
                    }
                }

                if (foundIdx !== -1) {
                    listModel.move(foundIdx, j, 1);
                } else {
                    listModel.insert(j, typeof targetItem === "object" ? targetItem : { "entryData": targetItem });
                }
            } else {
                listModel.append(typeof targetItem === "object" ? targetItem : { "entryData": targetItem });
            }
        }

        // 4. Remove any extra items beyond limit
        while (listModel.count > limit) {
            listModel.remove(listModel.count - 1);
        }
    }
}
