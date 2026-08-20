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

        for (var j = 0; j < limit; j++) {
            var targetItem = sourceArray[j];
            var targetKeyVal = (typeof targetItem === "object" && keyProp) ? targetItem[keyProp] : targetItem;
            var foundIdx = -1;

            for (var k = j; k < listModel.count; k++) {
                var modelItem = listModel.get(k);
                var modelKeyVal = (modelItem && keyProp && modelItem[keyProp] !== undefined) ? modelItem[keyProp] : (modelItem ? modelItem.entryData : modelItem);
                if (modelKeyVal === targetKeyVal) {
                    foundIdx = k;
                    break;
                }
            }

            if (foundIdx !== -1 && foundIdx !== j) {
                listModel.move(foundIdx, j, 1);
            }
        }

        for (var n = 0; n < limit; n++) {
            var insertItem = sourceArray[n];
            var insertKeyVal = (typeof insertItem === "object" && keyProp) ? insertItem[keyProp] : insertItem;
            var present = false;

            for (var m = 0; m < listModel.count; m++) {
                var itmCheck = listModel.get(m);
                var keyCheck = (itmCheck && keyProp && itmCheck[keyProp] !== undefined) ? itmCheck[keyProp] : (itmCheck ? itmCheck.entryData : itmCheck);
                if (keyCheck === insertKeyVal) {
                    present = true;
                    break;
                }
            }

            if (!present) {
                listModel.insert(n, typeof insertItem === "object" ? insertItem : { "entryData": insertItem });
            }
        }

        var targetMap = {};
        for (var t = 0; t < limit; t++) {
            var val = sourceArray[t];
            targetMap[(typeof val === "object" && keyProp) ? val[keyProp] : val] = true;
        }

        for (var r = listModel.count - 1; r >= 0; r--) {
            var curr = listModel.get(r);
            var currKey = (curr && keyProp && curr[keyProp] !== undefined) ? curr[keyProp] : (curr ? curr.entryData : curr);
            if (!curr || !targetMap[currKey]) {
                listModel.remove(r);
            }
        }
    }
}
