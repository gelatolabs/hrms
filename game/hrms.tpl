%{
username=`{get_cookie username | escape_html}
userid=`{get_cookie id | sed 's/[^a-z0-9]//g'}
userdir=etc/users/$userid

if(! ~ $"post_arg_email '')
    email=`{echo $post_arg_email | sed 's/[^a-z0-9]//g'}
if not
    email=`{ls -p $userdir/emails | sort -n | tail -n 1}
if(test -f $userdir/emails/$email/type)
    type=`{cat $userdir/emails/$email/type}

emailcount=`{ls $userdir/emails | wc -l}
switch(`{echo $emailcount'-('$emailcount'/16*16)' | bc}) {
case 1 2 3 6 7 8 11 12 13
    next=applications
case 4 9 14
    next=event
case 5 10 15
    next=firing
case 0
    next=review
}

if(~ $"post_arg_generateEmail yes) {
    if(~ $next applications && ! test -d $userdir/firing) {
        cd $sitedir
        python3 gamegen.py generateResumeEmail $userid $emailcount >/dev/null
        python3 gamegen.py generateResumeEmail $userid `{echo $emailcount+1 | bc} >/dev/null
        python3 gamegen.py generateResumeEmail $userid `{echo $emailcount+2 | bc} >/dev/null
        cd ../..
    }
    if not if(~ $next event && test -d $userdir/firing) {
        event=`{ls -p etc/templates/events | shuf -n1}
        cp -r etc/templates/events/$event $userdir/emails/$emailcount
    }
    if not if(~ $next firing) {
        reason=`{cat $userdir/firing/reason}
        cp -r $userdir/firing $userdir/emails/$emailcount
        cp etc/templates/firing/$reason $userdir/emails/$emailcount/body
    }
    if not if(~ $next review && test -d $userdir/firing) {
        cp -r etc/templates/review $userdir/emails/$emailcount
    }
}
if not if(~ $"post_arg_hireSubmit Hire && ! ~ $"post_arg_hire '' && ! test -d $userdir/firing) {
    candidate=`{echo $post_arg_hire | sed 's/[^a-z0-9]//g'}
    if(! test -f $userdir/emails/$candidate/hired) {
        score=`{cat $userdir/score}
        goodness=`{cat $userdir/emails/$candidate/goodness}
        echo $score+$goodness | bc > $userdir/score
        mv $userdir/emails/$candidate/firing $userdir/
        touch $userdir/emails/$candidate/hired
    }
}
if not if(~ $"post_arg_fireSubmit Fire) {
    rm -rf $userdir/firing
}
%}

<div id="header">
    <img src="img/header.png" />
    <span id="username" style="float: right"><span style="font-size: 90%">Hello,</span> <span style="font-weight: 600">%($username%).</span></span>
</div>
<table id="maintable"><tr>
<td class="noborder"><div style="width: 14vw"><table style="width: calc(100% + 1px)">
    <tr style="background-color: #fffc9d; cursor: pointer" onclick="generateEmail()"><td>
        <span><strong>☞ GET MAAAIL!! ☜</strong></span>
    </td></tr>
    <tr><td>
        <span>Inbox</span>
    </td></tr>
    <tr class="active"><td>
        <span><strong>Spam</strong></span>
%       unread=`{ls $userdir/emails/*/unread | wc -l}
%       if(! ~ $unread 0) {
        <span style="float: right"><strong>%($unread%)</strong></span>
%       }
    </td></tr>
    <tr><td>
        <span>Sent</span>
    </td></tr>
    <tr><td>
        <span>Trash</span>
    </td></tr>
    <tr style="height: auto"><td></td></tr>
    <tr style="height: 0"><td style="text-align: center">
        <img src="img/health-%(`{cat $userdir/health}%).png" style="width: 100%; margin-top: 8px" /><br />
        <label for="health">Mental Health</label><br />
        <progress id="health" value="%(`{cat $userdir/health}%)" max="100"></progress>
    </td></tr>
</table></div></td>
<td class="noborder"><div style="width: 25vw"><table style="width: calc(100% + 1px)">
%   for(i in `{ls -p $userdir/emails | sort -nr}) {
    <tr class="emailBtn %(`{if(~ $email $i) echo 'active'}%)" onclick="openEmail('%($i%)')"><td>
        <span>%(`{if(test -f $userdir/emails/$i/unread) echo '<strong>'}%)%(`{cat $userdir/emails/$i/subject}%)%(`{if(test -f $userdir/emails/$i/unread) echo '</strong>'}%)</span><br />
        <span>%(`{cat $userdir/emails/$i/sender}%)</span>
        <span style="float: right">%(`{/bin/date -r $userdir/emails/$i/body '+%H:%M:%S %Z'}%)</span>
    </td></tr>
%   }
    <tr><td></td></tr>
</table></div></td>
<td class="noborder"><div style="width: 61vw"><table style="width: calc(100% + 1px)">
    <tr style="background-color: #f4f4f4; height: 0"><td>
        <table style="height: auto" id="emaildetails">
          <tr><td style="text-align: right">From:</td><td>%(`{cat $userdir/emails/$email/sender}%)</td></tr>
          <tr><td style="text-align: right">Date:</td><td>%(`{/bin/date -r $userdir/emails/$email/body}%)</td></tr>
          <tr><td style="text-align: right">Subject:</td><td><strong>%(`{cat $userdir/emails/$email/subject}%)</strong></td></td>
        </table>
    </td></tr>
    <tr style="height: auto"><td id="emailbody">
%       if(~ $"type firing)
%           employee=`{cat $userdir/emails/$email/name}
%       tpl_handler $userdir/emails/$email/body
    </td></tr>
%   if(~ $type application && ! test -d $userdir/firing && ~ $next event && ! test -f $userdir/emails/$email/hired) {
    <tr><td>
        <form id="actions" method="POST" action="">
            <input type="hidden" name="hire" value="%($email%)">
            <input type="submit" name="hireSubmit" value="Hire" class="hire">
        </form>
    </td></tr>
%   }
%   if not if(~ $type firing && test -d $userdir/firing) {
    <tr><td>
        <form id="actions" method="POST" action="">
            <input type="submit" name="fireSubmit" value="Fire" class="fire">
        </form>
    </td></tr>
%   }
    <tr style="height: 60px; text-align: center"><td id="ad">
        <a href="https://gelatolabs.xyz/" target="_blank"><img src="/img/banner%(`{shuf -n1 -i 1-3}%).png" /></a>
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

function generateEmail() {
    var form = document.createElement("form");
    var generateBtn = document.createElement("input");

    form.method = "POST";
    form.action = "";

    generateBtn.name = "generateEmail";
    generateBtn.value = "yes";
    generateBtn.type = "hidden";

    form.appendChild(generateBtn);
    document.body.appendChild(form);
    form.submit();
}
</script>

% rm $userdir/emails/$email/unread
