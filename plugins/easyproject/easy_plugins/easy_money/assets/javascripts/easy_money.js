function computePriceWithVat(price1Id, price2Id, vatId) {
    var price1 = document.getElementById(price1Id);
    var price2 = document.getElementById(price2Id);
    var vat = document.getElementById(vatId);
    if (price2 != null && vat != null && price2.value != '' && !isNaN(price2.value) && vat.value != '' && !isNaN(vat.value)) {
        price1.value = Math.round(parseFloat(price2.value) * (100 + parseFloat(vat.value))) / 100;
    }
}

function computePriceWithoutVat(price1Id, price2Id, vatId) {
    var price1 = document.getElementById(price1Id);
    var price2 = document.getElementById(price2Id);
    var vat = document.getElementById(vatId);
    if (price1 != null && vat != null && price1.value != '' && !isNaN(price1.value) && vat.value != '' && !isNaN(vat.value)) {
        price2.value = Math.round((parseFloat(price1.value) * 100 / (100 + parseFloat(vat.value))) * 100) / 100;
    }
}

function toggleMoneySelection(el) {
    var boxes = el.getElementsBySelector('input[type=checkbox]');
    var all_checked = true;
    for (i = 0; i < boxes.length; i++) {
        if (boxes[i].checked == false) {
            all_checked = false;
        }
    }
for (i = 0; i < boxes.length; i++) {
    if (all_checked) {
        boxes[i].checked = false;
        boxes[i].up('tr').removeClassName('context-menu-selection');
    } else if (boxes[i].checked == false) {
        boxes[i].checked = true;
        boxes[i].up('tr').addClassName('context-menu-selection');
    }
}
}