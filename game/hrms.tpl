<style>
table {
    border-collapse: collapse;
}
td {
    border: 1px solid #000;
}
td.noborder {
    padding: 0;
    border: none;
}

#maintable {
    position: absolute;
    top: 2vh;
    right: 0;
    bottom: 0;
    left: 0;
}
</style>

<div style="height: 2vh">Welcome, %(`{get_cookie username}%) (%(`{get_cookie id}%)).</div>

<table id="maintable"><tr style="height: calc(98vh - 2px)">
<td class="noborder"><table style="width: 8em">
    <tr style="height: 2em"><td>
        Inbox
    </td></tr>
    <tr style="height: 2em"><td>
        Spam
    </td></tr>
    <tr style="height: 2em"><td>
        Sent
    </td></tr>
    <tr style="height: 2em"><td>
        Trash
    </td></tr>
    <tr style="height: calc(98vh - 8em - 2px)"><td></td></tr>
</table></td>
<td class="noborder"><table style="width: 24em">
    <tr style="height: 2em"><td>
        Some email
    </td></tr>
    <tr style="height: 2em"><td>
        Some email
    </td></tr>
    <tr style="height: 2em"><td>
        Some email
    </td></tr>
    <tr style="height: calc(98vh - 6em - 2px)"><td></td></tr>
</table></td>
<td class="noborder"><table style="width: calc(100vw - 32em)">
    <tr style="height: 2em"><td>
        Email info
    </td></tr>
    <tr style="height: calc(98vh - 2em - 2px)"><td>
        The actual email
    </td></tr>
</tr></table>
