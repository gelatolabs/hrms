%{
username=`{get_cookie username | escape_html}
userdir=etc/users/`{get_cookie id | sed 's/[^a-z0-9]//g'}

if(! ~ $"post_arg_email '')
    email=`{echo $post_arg_email | sed 's/[^0-9]//g'}
if not
    email=`{ls -trp $userdir/emails | tail -n 1}
%}

<style>
body {
    overflow: hidden;
}

div {
    height: 100%;
    overflow-x: hidden;
    overflow-y: auto;
}

table {
    height: 100vh;
    border-collapse: collapse;
}
td {
    vertical-align: baseline;
    border: 1px solid #000;
    padding: 6px;
}
td.noborder {
    padding: 0;
    border: none;
}
tr {
    height: 0;
}
tr:last-child {
    height: auto;
}

#maintable {
    position: absolute;
    top: 0;
    right: 0;
    bottom: 0;
    left: 0;
}

#emaildetails td {
    border: none;
    padding: 0 6px 0 0;
}
#emailbody {
    padding: 0 1.5em 0.5em 1.5em;
}

.active {
    background-color: #ddd;
}
</style>

<table id="maintable"><tr>
<td class="noborder"><table style="width: 14vw">
    <tr><td>
        Inbox
    </td></tr>
    <tr class="active"><td>
        Spam
    </td></tr>
    <tr><td>
        Sent
    </td></tr>
    <tr><td>
        Trash
    </td></tr>
    <tr style="height: auto"><td></td></tr>
    <tr style="height: 0"><td>
        %($username%)
    </td></tr>
</table></td>
<td class="noborder"><div style="width: 25vw"><table style="width: 100%">
%   for(i in `{ls -tp $userdir/emails}) {
    <tr class="emailBtn %(`{if(~ $email $i) echo 'active'}%)" onclick="openEmail(%($i%))"><td>
        <span><strong>%(`{cat $userdir/emails/$i/subject}%)</strong></span><br />
        <span>%(`{cat $userdir/emails/$i/sender}%)</span>
        <span style="float: right">%(`{/bin/date -r $userdir/emails/$i/body '+%H:%M:%S %Z'}%)</span>
    </td></tr>
%   }
    <tr><td></td></tr>
</table></div></td>
<td class="noborder"><div style="width: 61vw"><table style="width: 100%">
    <tr><td>
        <table style="height: auto" id="emaildetails">
          <tr><td>Subject:</td><td><strong>%(`{cat $userdir/emails/$email/subject}%)</strong></td></td>
          <tr><td>From:</td><td>%(`{cat $userdir/emails/$email/sender}%)</td></tr>
          <tr><td>Date:</td><td>%(`{/bin/date -r $userdir/emails/$email/body}%)</td></tr>
        </table>
    </td></tr>
    <tr><td id="emailbody">
        %(`{tpl_handler $userdir/emails/$email/body}%)
    </td></tr>
</table></div></td>
</tr></table>

<script>
function openEmail(email) {
    var form = document.createElement("form");
    var emailVal = document.createElement("input");

    form.method = "POST";
    form.action = "";

    emailVal.name = "email";
    emailVal.value = email;
    emailVal.type = "hidden";

    form.appendChild(emailVal);
    document.body.appendChild(form);
    form.submit();
}
</script>
