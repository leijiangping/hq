<%@ page language="java" %>
<%@ page errorPage="/common/Error.jsp" %>
<%@ taglib uri="struts-html-el" prefix="html" %>
<%@ taglib uri="struts-tiles" prefix="tiles" %>
<%@ taglib uri="jstl-fmt" prefix="fmt" %>
<%@ taglib uri="display" prefix="display" %>
<%@ taglib uri="jstl-c" prefix="c" %>

<%--
  NOTE: This copyright does *not* cover user programs that use HQ
  program services by normal system calls through the application
  program interfaces provided as part of the Hyperic Plug-in Development
  Kit or the Hyperic Client Development Kit - this is merely considered
  normal use of the program, and does *not* fall under the heading of
  "derived work".

  Copyright (C) [2004-2009], Hyperic, Inc.
  This file is part of HQ.

  HQ is free software; you can redistribute it and/or modify
  it under the terms version 2 of the GNU General Public License as
  published by the Free Software Foundation. This program is distributed
  in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
  even the implied warranty of MERCHANTABILITY or FITNESS FOR A
  PARTICULAR PURPOSE. See the GNU General Public License for more
  details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  USA.
 --%>
<script  src='<html:rewrite page="/js/scriptaculous.js"/>' type="text/javascript"></script>
<script src='<html:rewrite page="/js/dashboard.js"/>' type="text/javascript"></script>
<script src='<html:rewrite page="/js/effects.js"/>' type="text/javascript"></script>
<script src='<html:rewrite page="/js/popup.js"/>' type="text/javascript"></script>
<script src='<html:rewrite page="/js/window.js"/>' type="text/javascript"></script>
<script type="text/javascript">
onloads.push(requestViewEscalation);

document.toggleSubmit = function(e){
    if(e && e.keyCode == 13){
        saveEscalation();
        e.stopPropagation ();
        e.preventDefault();
    }
}

dojo.addOnLoad(function(){
    dojo11.connect(document, 'onkeypress', document.toggleSubmit);
    dojo11.connect(document.forms[0], 'onkeypress', document.toggleSubmit);
    dojo11.connect(document.forms[1], 'onkeypress', document.toggleSubmit);
});

var selUserEsc;
var selActionTypeEsc;

function requestViewEscalation() {
    var alertDefId = dojo11.byId('alertDefId').value;
    var url = '<html:rewrite page="/escalation/jsonByEscalationId/"/>';
    url += escape('<c:out value="${param.escId}"/>');
    url += '.do';
    
    new Ajax.Request(url, {method: 'get', onSuccess:showViewEscResponse, onFailure :reportError});
}


function showViewEscResponse(originalRequest) {
	var tmp = eval('(' + originalRequest.responseText + ')');
    if(tmp.error){
        var escmsg = dojo11.byId('errMsg');
        escmsg.innerHTML = tmp.error;
        var example = dojo11.byId('escError');
        example.style.display= '';
    } else{
        dojo11.byId('escMsg').innerHTML = '';
        dojo11.byId('example').style.display= 'none';
        dojo11.byId('errMsg').innerHTML = '';
        dojo11.byId('escError').style.display= 'none';
      
        var creationTime = tmp.escalation.creationTime;
        var notifyAll = tmp.escalation.notifyAll;
        var repeat = tmp.escalation.repeat;
        var _version_ = tmp.escalation._version_;
        var modifiedTime = tmp.escalation.modifiedTime;
        var actions = tmp.escalation.actions;
        var allowPause = tmp.escalation.allowPause;
        var escName = tmp.escalation.name;
        var description = tmp.escalation.description;
        var id = tmp.escalation.id;
	    var maxWaitTime = formatWaitTime(null, tmp.escalation.maxWaitTime, '<fmt:message key="alert.config.props.CB.Enable.TimeUnit.2"/>',  '<fmt:message key="alert.config.props.CB.Enable.TimeUnit.1"/>');
    
        dojo11.byId('viewEscalation').style.display = "";
    
        dojo11.byId('escId').value = id;
        dojo11.byId('id').value = id;
    
        dojo11.byId('name').innerHTML = '<b>' + escName + '</b>';
        dojo11.byId('escName').value = escName;
    
        dojo11.byId('description').innerHTML = description + "&nbsp;";
        if (description) {
            dojo11.byId('escDesc').value = description;
        }
    
        if (allowPause) {
            if (tmp.escalation.maxWaitTime == <%= Long.MAX_VALUE %>) {
                dojo11.byId('acknowledged').innerHTML = '<fmt:message key="alert.config.escalation.allow.pause.indefinitely" />';
            } else {
            	dojo11.byId('acknowledged').innerHTML = '<fmt:message key="alert.config.escalation.allow.pause" /> ' + maxWaitTime;
            }
            dojo11.byId('allowPauseTrue').checked = "true";

            var sel = dojo11.byId('maxWaitTime');
            for (var i = 0; sel.selectedIndex == 0 && i < sel.length; i++) {
                sel.options[i].selected =
                    (sel.options[i].value == tmp.escalation.maxWaitTime);
            }
        }
        else {
            dojo11.byId('acknowledged').innerHTML = '<fmt:message key="alert.config.escalation.allow.continue" />';
            dojo11.byId('allowPauseFalse').checked = "true";
        }
    
        if (notifyAll) {
            dojo11.byId('changed').innerHTML = '<fmt:message key="alert.config.escalation.state.change.notify.all" />';
            dojo11.byId('notifyAllTrue').checked = "true";
    
        }
        else {
            dojo11.byId('changed').innerHTML = '<fmt:message key="alert.config.escalation.state.change.notify.previous" />';
            dojo11.byId('notifyAllFalse').checked = "true";
    
        }

        if (repeat) {
            dojo11.byId('ended').innerHTML = '<fmt:message key="alert.config.escalation.state.ended.repeat" />';
            dojo11.byId('repeatTrue').checked = "true";
        }
        else {
            dojo11.byId('ended').innerHTML = '<fmt:message key="alert.config.escalation.state.ended.stop" />';
            dojo11.byId('repeatFalse').checked = "true";
        }
    
        var escViewUL = dojo11.byId('viewEscalationUL');
    
        for (var i = escViewUL.childNodes.length - 1; i > -1; i--) {
            escViewUL.removeChild(escViewUL.childNodes[i]);
        }
    
        if (actions.length == 0) {
            dojo11.byId('step2create').style.display = '';
            dojo11.byId('noActions').style.display = "";
        }
        else {
            dojo11.byId('step2create').style.display = 'none';
            dojo11.byId('viewSection').style.display = "";
        }
    
        dojo11.byId('creationTime').value = creationTime;
        dojo11.byId('notifyAll').value = notifyAll;
        dojo11.byId('_version_').value = _version_;
        dojo11.byId('modifiedTime').value = modifiedTime;
        dojo11.byId('allowPause').value = allowPause;
        dojo11.byId('id').value = id;
        dojo11.byId('repeat').value = repeat;

        for (i = 0; i < actions.length; i++) {
            var actionConfig = actions[i].action.config;
            var configListType = actionConfig.listType;
            var configNames = actionConfig.names;
            var configSms = actionConfig.sms;
            var configMeta = actionConfig.meta;
            var configVersion = actionConfig.version;
            var configProduct = actionConfig.product;
            var configSnmpOID = actionConfig.oid;
            var configSnmpIP = actionConfig.address;
            var actionId = actions[i].action.id;
            var actionsClassName = actions[i].action.className;
            var actionsVersion = actions[i].action._version_;
            var actionWaitTime = formatWaitTime(null, actions[i].waitTime, '<fmt:message key="alert.config.props.CB.Enable.TimeUnit.2"/>',  '<fmt:message key="alert.config.props.CB.Enable.TimeUnit.1"/>');
            
            var liID = actionId;
            var viewLi = document.createElement('li');
            var remDiv = document.createElement('div');
            var usersDiv = document.createElement('div');
            var usersTextDiv = document.createElement('div');
            var usersEditDiv = document.createElement('div');
            var rolesDiv = document.createElement('div');
            var othersDiv = document.createElement('div');
            var waitDiv = document.createElement('div');
            var editWaitDiv = document.createElement('div');
            var sysDiv = document.createElement('div');
            var snmpDiv = document.createElement('div');
            var escTable = document.createElement('table');
            var escTableBody = document.createElement('tbody');
            var escTr1 = document.createElement('tr');
            var escTr2 = document.createElement('tr');
            var escTrHeader = document.createElement('tr');
            var td1 = document.createElement('td');
            var td2 = document.createElement('td');
            var td3 = document.createElement('td');
            var td4 = document.createElement('td');
            var td5 = document.createElement('td');
            var td6 = document.createElement('td');
            var td7 = document.createElement('td');
            var td8 = document.createElement('td');
            var select1 = document.createElement("select");
            var select2 = document.createElement("select");
            var select3 = document.createElement("select");
            var anchor = document.createElement("a");
    
            var emailInfo = actionConfig.names;
    
            escViewUL.appendChild(viewLi)
    		
            viewLi.setAttribute((document.all ? 'className' : 'class'), "BlockContent");
            viewLi.setAttribute('id', 'row_' + liID);
            dojo11.byId('row_' + liID).style.margin = "0px";
            dojo11.byId('row_' + liID).style.padding = "0px";
    
            viewLi.appendChild(escTable);
            escTable.setAttribute((document.all ? 'className' : 'class'), "escTbl");
            escTable.setAttribute('id', 'escTbl_' + liID);
            escTable.setAttribute('border', '0');
            escTable.setAttribute('cellpadding', '2');
    
            escTable.appendChild(escTableBody);
            escTableBody.appendChild(escTrHeader);
            escTableBody.appendChild(escTr2);
            escTableBody.appendChild(escTr1);
    
    
            escTrHeader.appendChild(td6);
            td6.setAttribute('colSpan', '3');
            td6.setAttribute((document.all ? 'className' : 'class'), "BlockTitle");
            td6.innerHTML = '<div style="cursor:move;background:#cccccc;padding:2px; border:1px solid #aeb0b5;">Action Details</div>';
    
        <c:if test="${useroperations['modifyEscalation']}">
            escTrHeader.appendChild(td8);
            td8.setAttribute('vAlign', 'top');
            td8.setAttribute('rowSpan', '3');
            td8.setAttribute('width', '15%');
            td8.setAttribute((document.all ? 'className' : 'class'), "remove");
            td8.innerHTML = '<a href="#" onclick="removeRow(this);removeAction(' + actionId + ');"><html:img page="/images/tbb_delete.gif" height="16" width="46" border="0"  alt="" /></a>';
        </c:if>
    
            escTr1.appendChild(td1);
            td1.setAttribute((document.all ? 'className' : 'class'), "waitTd");
            td1.setAttribute('colSpan', '3');
            td1.appendChild(waitDiv);
            waitDiv.setAttribute('id', 'wait_' + liID);
            waitDiv.innerHTML = "Wait time before escalating: " + actionWaitTime + "<br>";
    
    
            td1.appendChild(editWaitDiv);
            editWaitDiv.setAttribute('id', 'editWait_' + liID);
    
            escTr2.appendChild(td2);
            td2.setAttribute('vAlign', 'top');
            td2.setAttribute((document.all ? 'className' : 'class'), "wrap");
            td2.appendChild(usersTextDiv);
            td2.setAttribute('id', 'usersList_' + liID);
    
            var actionClass = actionsClassName.split('.');
    
            for (var d = 0; d < actionClass.length; d++) {
                if (actionClass[d] == "SyslogAction") {
                    usersTextDiv.innerHTML = '<table cellpadding="0" cellspacing="0" border="0"><tr><td rowSpan="3" vAlign="top" style="padding-right:3px;">Log to the Syslog:</td><td style="padding:0px 2px 2px 2px;">meta: ' + configMeta + '</td></tr><tr><td style="padding:2px;">product: ' + configProduct + '</td></tr><tr><td style="padding:2px 2px 2px 2px;">version: ' + configVersion + '</td></tr></table>'
                } else if (actionClass[d] == "NoOpAction") {
                    usersTextDiv.innerHTML = 'Suppress duplicate alerts for: ' + actionWaitTime;
                    waitDiv.innerHTML = "&nbsp;";
                } else if (actionClass[d] == "SnmpAction") {
                    usersTextDiv.innerHTML = '<table cellpadding="0" cellspacing="0" border="0"><tr><td rowSpan="3" vAlign="top" style="padding-right:3px;">Snmp Trap:</td><td style="padding:0px 2px 2px 2px;"><fmt:message key="resource.autodiscovery.server.IPAddressTH"/>: ' + configSnmpIP + '</td></tr><tr><td style="padding:2px;"><fmt:message key="admin.settings.SNMPTrapOID"/> ' + configSnmpOID + '</td></tr></table>'
                }
            }
    
            if (configListType == "1") {
                var emailAdds = emailInfo.split(',');
                for (var b = 0; b < emailAdds.length; b++) {
                    var displayEmails = "";
                    var emailAdds = emailInfo.split(',');
                    var comma = ", ";
                    for (var b = 0; b < emailAdds.length; b++) {
                        displayEmails += emailAdds[b];
    
                        if (b < emailAdds.length - 1) {
                            displayEmails += comma;
                        }
                    }
    
                    if (configSms == "true") {
                        usersTextDiv.innerHTML = "<fmt:message key="monitoring.events.MiniTabs.Others"/> <fmt:message key="alert.config.action.notify.via.sms"/> " + displayEmails + "<br>";
                    } else {
                        usersTextDiv.innerHTML = "<fmt:message key="monitoring.events.MiniTabs.Others"/> <fmt:message key="alert.config.action.notify.via.email"/> " + displayEmails + "<br>";
    
                    }
                    //usersTextDiv.innerHTML = "<fmt:message key="monitoring.events.MiniTabs.Others"/>:  " + displayEmails + "<br>";
    
                }
    
            } else if (configListType == "2") {
                var uids = emailInfo.split(',');
                var userNames = "";
                for (var b = 0; b < uids.length; b++) {
                <c:forEach var="user" items="${AvailableUsers}" varStatus="status">
                    if (uids[b] == '<c:out value="${user.id}"/>') {
                        userNames += '<c:out value="${user.name}" />, ';
                    }
                </c:forEach>
                }
    
                if (configSms == "true") {
                    usersTextDiv.innerHTML = "<fmt:message key="monitoring.events.MiniTabs.Users"/> <fmt:message key="alert.config.action.notify.via.sms"/> " + userNames + "<br>";
                } else {
                    usersTextDiv.innerHTML = "<fmt:message key="monitoring.events.MiniTabs.Users"/> <fmt:message key="alert.config.action.notify.via.email"/> " + userNames + "<br>";
    
                }
            } else  if (configListType == "3") {
                var rids = emailInfo.split(',');
                var roleNames = "";
                for (var b = 0; b < rids.length; b++) {
                <c:forEach var="role" items="${AvailableRoles}" varStatus="status">
                    if (rids[b] == '<c:out value="${role.id}"/>') {
                        roleNames += '<c:out value="${role.name}" />, ';
                    }
                </c:forEach>
                }
    
                if (configSms == "true") {
                    usersTextDiv.innerHTML = "<fmt:message key="monitoring.events.MiniTabs.Roles"/> <fmt:message key="alert.config.action.notify.via.sms"/> " + roleNames + "<br>";
                } else {
                    usersTextDiv.innerHTML = "<fmt:message key="monitoring.events.MiniTabs.Roles"/> <fmt:message key="alert.config.action.notify.via.email"/> " + roleNames + "<br>";
                }
            }
    
            escTr2.appendChild(td3);
            td3.setAttribute((document.all ? 'className' : 'class'), "td3");
            td3.setAttribute('width', '20%');
            td3.setAttribute('vAlign', 'top');
    
            switch (configListType) {
                case 1:
                    td3.innerHTML = emailInfo + "<br>";
                break;
                default:
                    td3.innerHTML = '&nbsp;';
                break;
            }
    
            td3.style.paddingTop = "5px";
    
            escTr2.appendChild(td4);
            td5.setAttribute('width', '50%');
    
            td4.appendChild(usersEditDiv);
            usersEditDiv.style.display = 'none';
            usersEditDiv.setAttribute('class', 'escInput' + liID);
            usersEditDiv.setAttribute('id', 'usersEditDiv_' + liID);
            usersEditDiv.setAttribute('width', '40%');
            usersEditDiv.innerHTML = " ";
            dojo11.byId('pauseTimeText').innerHTML = 'Allow user to pause escalation: ' + allowPause + "<br>";
        }
    
        <c:if test="${useroperations['modifyEscalation']}">
        Sortable.create('viewEscalationUL', {containment:'viewEscalationUL',
            onUpdate: function() {
                var pars = "&id=" + id;
                var url = '<html:rewrite action="/escalation/updateEscalationOrder"/>?' + Sortable.serialize("viewEscalationUL") + pars;
                new Ajax.Request(url, {method: 'post', onFailure :reportError});
            },
            constraint: 'vertical'});
        </c:if>
    }
}

function editEscalation() {
    dojo11.byId('escPropertiesTable').style.display = 'none';
    dojo11.byId('editPropertiesTable').style.display = '';
}

function cancelEditEscalation() {
    dojo11.byId('escPropertiesTable').style.display = '';
    dojo11.byId('editPropertiesTable').style.display = 'none';
}

function saveEscalation() {
    var escName = dojo11.byId('escName').value;
    if (escName == "") {
        alert('<fmt:message key="alert.config.error.escalation.name.required"/>');
        return false;
    }

    var escDesc = dojo11.byId('escDesc').value;
    if (escName.match(/['"]/) || escDesc.match(/['"]/)) {
        alert('<fmt:message key="error.input.badquotes"/>');
        return false;
    }

    var pars = Form.serialize('EscalationForm');
    var url = '<html:rewrite action="/escalation/updateEscalation"/>';
    new Ajax.Request(url, {method: 'post', parameters: pars, onComplete: showViewEscResponse, onFailure: reportError});
    dojo11.byId('escPropertiesTable').style.display = '';
    dojo11.byId('editPropertiesTable').style.display = 'none';

}

function updateEscView(originalRequest) {
    dojo11.byId('example').setAttribute((document.all ? 'className' : 'class'), "ConfirmationBlock");
    dojo11.byId('example').style.display = '';
    dojo11.byId('okCheck').innerHTML = '<html:img page="/images/tt_check.gif" height="9" width="9" border="0" alt="" />';
    dojo11.byId('escMsg').innerHTML = "The action has been added to the escalation. The escalation is complete. You can add additional actions as needed.";
    cancelAddEscalation();
    setTimeout("requestViewEscalation()", 1200);
    //requestViewEscalation();
}

function hideAddEscButtons() {
    dojo11.byId('addEscButtons').style.display = "none";
    dojo11.byId('addRowButton').style.display = "";
}

function showAddEscButton() {
    dojo11.byId('addRowButton').style.display = "";
}

function addRow() {
    dojo11.byId('addEscalationUL').style.display = "";
    dojo11.byId('addEscButtons').style.display = "";
    dojo11.byId('noActions').style.display = "none";
    dojo11.byId('addRowButton').style.display = "none";
    
    var ni = dojo11.byId('addEscalationUL');
    var numi = document.getElementById('theValue');
    var num = (document.getElementById('theValue').value - 1) + 2;

    //numi.value = num;
    var liID = 'row' + num;
    var escLi = document.createElement('li');
    var usersDiv = document.createElement('div');
    var rolesDiv = document.createElement('div');
    var othersDiv = document.createElement('div');
    var emailDiv = document.createElement('div');
    var sysDiv = document.createElement('div');
    var snmpDiv = document.createElement('div');
    var escTable = document.createElement('table');
    var escTableBody = document.createElement('tbody');
    var escTrHeader = document.createElement('tr');
    var escTr1 = document.createElement('tr');
    var escTr2 = document.createElement('tr');
    var td1 = document.createElement('td');
    var td2 = document.createElement('td');
    var td3 = document.createElement('td');
    var td4 = document.createElement('td');
    var td5 = document.createElement('td');
    var td6 = document.createElement('td');
    var td7 = document.createElement('td');
    var select1 = document.createElement("select");
    var select2 = document.createElement("select");
    var select3 = document.createElement("select");
    var anchor = document.createElement("a");

    ni.appendChild(escLi);
    escLi.setAttribute((document.all ? 'className' : 'class'), "lineitem");
    escLi.setAttribute('id', 'row_' + liID);

    escLi.appendChild(escTable);
    escTable.setAttribute((document.all ? 'className' : 'class'), "escTbl");
    escTable.setAttribute('border', '0');
    escTable.appendChild(escTableBody);
    escTableBody.appendChild(escTrHeader);
    escTableBody.appendChild(escTr2);
    escTableBody.appendChild(escTr1);

    escTrHeader.appendChild(td6);
    td6.setAttribute('colSpan', '3');
    td6.setAttribute((document.all ? 'className' : 'class'), "BlockTitle");
    td6.innerHTML = '<div style="width:100%;background:#cccccc;">Create an Action for this escalation</div>';

    escTrHeader.appendChild(td5);
    td5.setAttribute('vAlign', 'top');
    td5.setAttribute('width', '30%');
    td5.setAttribute('rowSpan', '3');
    td5.setAttribute('id', 'displaySelAction');
    td5.innerHTML = '<table cellpadding="2" cellspacing="0" border="0" width="100%"><tbody><tr><td class=BlockTitle colSpan=3>Action Details</td></tr><tr><td id="actionName" vAlign="top" width="50%">Action: Email</td></tr><tr><td id="userListDisplay" valign="top" style="display:none;"></td></tr><tr><td><table cellpadding="2" cellspacing="0" border="0"><tr><td id=metaText style="display:none"></td></tr><tr><td id=productText style="display:none"></td></tr><tr><td id=versionText style="display:none"></td></tr></table></td></tr><tr><td><table cellpadding="2" cellspacing="0" border="0"><tr><td id=IPText style="display:none"></td></tr><tr><td id=OIDText style="display:none"></td></tr></table></td></tr><tr><td id="time" colspan="3" valign="top" style="display:none;"></td></tr></tbody></table>';


    escTr1.appendChild(td1);

    td1.setAttribute('colSpan', '3');
    td1.appendChild(document.createTextNode('<fmt:message key="alert.config.escalation.then"/> '));

    td1.appendChild(select1);
    select1.setAttribute('id', 'waittime_' + liID);
    select1.onchange = function() {
        onchange_time(this);
    }
    select1.setAttribute('name', 'waittime');
    addOption(select1, '0', '<fmt:message key="alert.config.escalation.end"/>');
    addOption(select1, '300000', '<fmt:message key="alert.config.escalation.wait.minutes"><fmt:param value="5"/></fmt:message>');
    addOption(select1, '600000', '<fmt:message key="alert.config.escalation.wait.minutes"><fmt:param value="10"/></fmt:message>');
    addOption(select1, '1200000', '<fmt:message key="alert.config.escalation.wait.minutes"><fmt:param value="20"/></fmt:message>');
    addOption(select1, '1800000', '<fmt:message key="alert.config.escalation.wait.minutes"><fmt:param value="30"/></fmt:message>');
    addOption(select1, '2700000', '<fmt:message key="alert.config.escalation.wait.minutes"><fmt:param value="45"/></fmt:message>');
    addOption(select1, '3600000', '<fmt:message key="alert.config.escalation.wait.minutes"><fmt:param value="60"/></fmt:message>');
    addOption(select1, '14400000', '<fmt:message key="alert.config.escalation.wait.hours"><fmt:param value="4"/></fmt:message>');
    addOption(select1, '28800000', '<fmt:message key="alert.config.escalation.wait.hours"><fmt:param value="8"/></fmt:message>');
    addOption(select1, '86400000', '<fmt:message key="alert.config.escalation.wait.hours"><fmt:param value="24"/></fmt:message>');

    escTr2.appendChild(td2);
    td2.setAttribute('valign', 'top');
    td2.setAttribute('class', 'td2');

    td2.appendChild(select2);
    select2.setAttribute('id', 'Email_' + liID);
    select2.onchange = function() {
        onchange_handler(this);
        clearDisplay();
        clearOthers();
    }
    select2.setAttribute('name', 'action');
    addOption(select2, 'Select', '<fmt:message key="alert.config.escalation.notify.how"/>');
    addOption(select2, 'Email', 'Email');
    addOption(select2, 'SMS', 'SMS');
    addOption(select2, 'Syslog', 'Sys Log');
<c:if test="${snmpEnabled}">
    addOption(select2, 'SNMP', 'SNMP Trap');
</c:if>
    addOption(select2, 'NoOp', 'Suppress Alerts');

    escTr2.appendChild(td3);
    td3.setAttribute('class', 'td3');
    td3.setAttribute('valign', 'top');

    td3.appendChild(select3);
    select3.setAttribute('name', 'who');
    select3.setAttribute('id', 'who_' + liID);
    select3.onchange = function() {
        onchange_who(this);
        clearDisplay();
    }
    addOption(select3, 'Select', '<fmt:message key="alert.config.escalation.notify.who"/>');
<c:if test="${not empty AvailableRoles}">
    addOption(select3, 'Roles', '<fmt:message key="monitoring.events.MiniTabs.Roles"/>')
</c:if>
    addOption(select3, 'Users', '<fmt:message key="monitoring.events.MiniTabs.Users"/>');
    addOption(select3, 'Others', '<fmt:message key="monitoring.events.MiniTabs.Others"/>');

    escTr2.appendChild(td4);
    td4.setAttribute('valign', 'top');
    td4.setAttribute('align', 'left');

    td4.appendChild(emailDiv);
    emailDiv.setAttribute('class', 'emailDiv');
    emailDiv.setAttribute('id', 'emailinputDiv');
    dojo11.byId('emailinputDiv').style.display = 'none';
    dojo11.byId('emailinputDiv').innerHTML = "email addresses (comma separated):<br><textarea rows=2 cols=20 id=emailinput name=emailinput onMouseOut=checkEmail();copyOthersEmail(this);></textarea>";

    td4.appendChild(sysDiv);
    sysDiv.setAttribute('class', 'escInput');
    sysDiv.setAttribute('id', 'sysloginput');
    dojo11.byId('sysloginput').style.display = 'none';
    dojo11.byId('sysloginput').style.textAlign = 'left';
    //sysDiv.setAttribute('width', '40%');
    sysDiv.innerHTML = "meta:<br> <input type=text name=meta id=metainput" + " size=30 onMouseOut=copyMeta(this);checkMeta();><br>" + "product:<br> <input type=text name=product id=productinput" + " size=30 onMouseOut=copyProduct(this);checkProduct();><br>" + "version:<br> <input type=text name=version id=versioninput" + " size=30 onMouseOut=copyVersion(this);checkVersion();><br>";

    td4.appendChild(snmpDiv);
    snmpDiv.setAttribute('class', 'escInput');
    snmpDiv.setAttribute('id', 'snmpinput');
    dojo11.byId('snmpinput').style.display = 'none';
    dojo11.byId('snmpinput').style.textAlign = 'left';
    //sysDiv.setAttribute('width', '40%');
    snmpDiv.innerHTML = '<fmt:message key="resource.autodiscovery.server.IPAddressTH"/>: <fmt:message key="inform.config.escalation.scheme.IPAddress"/><br> <input type=text name=snmpIP id=snmpIPinput' + " size=30 onMouseOut=copysnmpIP(this);checkIP(this);><br>" + '<fmt:message key="admin.settings.SNMPTrapOID"/> <fmt:message key="inform.config.escalation.scheme.OID"/><br> <input type=text name=snmpOID id=snmpOIDinput' + " size=30 onMouseOut=copysnmpOID(this);checkOID(this);><br>";

    td4.appendChild(usersDiv);
    usersDiv.setAttribute('id', 'usersDiv' + liID);
    dojo11.byId('usersDiv' + liID).style.display = 'none';

    if (dojo11.byId('usersList')) {
        usersDiv.innerHTML = dojo11.byId('usersList').innerHTML;
        var usersInputList = usersDiv.getElementsByTagName('input');
        for (i = 0; i < usersInputList.length; i++) {
            var inputNamesArr = usersInputList[i];
            inputNamesArr.name = inputNamesArr.name;
        }
    }

    td4.appendChild(rolesDiv);
    rolesDiv.setAttribute('id', 'rolesDiv' + liID);
    dojo11.byId('rolesDiv' + liID).style.display = 'none';

    if (dojo11.byId('rolesList')) {
        rolesDiv.innerHTML = dojo11.byId('rolesList').innerHTML;
        var rolesInputList = rolesDiv.getElementsByTagName('input');
        for (i = 0; i < rolesInputList.length; i++) {
            var inputRolesArr = rolesInputList[i];
            inputRolesArr.name = inputRolesArr.name;
        }
    }

}

function copyOthersEmail(el) {
    var othersDisplay = dojo11.byId('userListDisplay');
    othersDisplay.style.display = "";
    othersDisplay.innerHTML = 'Notify email addresses: ' + el.value;
}

function copyMeta(el) {
    var metaDisplay = dojo11.byId('metaText');
    metaDisplay.style.display = "";
    metaDisplay.innerHTML = 'meta: ' + el.value;
}

function copyProduct(el) {
    var productDisplay = dojo11.byId('productText');
    productDisplay.style.display = "";
    productDisplay.innerHTML = 'product: ' + el.value;
}

function copyVersion(el) {
    var versionDisplay = dojo11.byId('versionText');
    versionDisplay.style.display = "";
    versionDisplay.innerHTML = 'version: ' + el.value;
}

function copysnmpOID(el) {
    var OIDDisplay = dojo11.byId('OIDText');
    OIDDisplay.style.display = "";
    OIDDisplay.innerHTML = '<fmt:message key="admin.settings.SNMPTrapOID"/> ' + el.value;
}

function copysnmpIP(el) {
    var IPDisplay = dojo11.byId('IPText');
    IPDisplay.style.display = "";
    IPDisplay.innerHTML = '<fmt:message key="resource.autodiscovery.server.IPAddressTH"/>: ' + el.value;
}

function clearDisplay() {
    dojo11.byId('userListDisplay').innerHTML = "";
    dojo11.byId('metaText').innerHTML = "";
    dojo11.byId('productText').innerHTML = "";
    dojo11.byId('versionText').innerHTML = "";
    dojo11.byId('time').innerHTML = "";
    dojo11.byId('IPText').innerHTML = "";
    dojo11.byId('OIDText').innerHTML = "";
}

function clearOthers() {
    dojo11.byId('emailinput').value = "";
    dojo11.byId('emailinputDiv').style.display = "none";
}

function onchange_handler(el) {

    var writeAction = dojo11.byId('actionName');
    var index = el.options[el.selectedIndex].value

    clearDisplay();
    dojo11.byId('escMsg').innerHTML = '';
    dojo11.byId('example').style.display = 'none';
    dojo11.byId('userListDisplay').style.display = "";

    if (index == "NoOp") {
        writeAction.innerHTML = '<fmt:message key="inform.config.escalation.scheme.NoOP"/>';
    } else {
        writeAction.innerHTML = 'Action: ' + index;
    }

    if (index == "Email" || index == "SMS" || index == "NoOp" || index == "SNMP" || index == 'Select') {
        hideSyslogInput(el);
    } else {
        showSyslogInput(el);
    }

    if (index == "SNMP") {
        showSnmpInput(el);
    }
    else {
        hideSnmpInput(el);
    }

    if (index == "Syslog" || index == "NoOp" || index == "SNMP") {
        hideWhoSelect(el);
    }
    else {
        showWhoSelect(el);
    }
    selActionTypeEsc = index;
}

function onchange_who(el) {
    clearOthers();
    dojo11.byId('escMsg').innerHTML = '';
    dojo11.byId('example').style.display = 'none';
    dojo11.byId('addEscButtons').style.display = "";


    var index = el.options[el.selectedIndex].value
    var idStr = el.id;
    var getId = idStr.split('_');
    var rolesDivIn = dojo11.byId('rolesDiv' + getId[1]);
    var usersDivIn = dojo11.byId('usersDiv' + getId[1]);
    var emailDivIn = dojo11.byId('emailinputDiv');

    if (index == "Roles") {
        emailDivIn.style.display = 'none';
        configureRoles(idStr);
    } else if (index == "Users") {
        emailDivIn.style.display = 'none';
        configureUsers(idStr);
        //configureUsers(nodeId);
    } else if (index == "Others") {
        emailDivIn.style.display = '';
        dojo11.byId('emailinput').focus();
        //configureOthers(nodeId);
    }
    selUserEsc = index;
}

function showWhoSelect(el) {
    var idStr = el.id;
    var getId = idStr.split('_');
    var whoSelector = dojo11.byId('who_' + getId[1]);
    whoSelector.style.display = '';
}

function hideWhoSelect(el) {
    var idStr = el.id;
    var getId = idStr.split('_');
    var whoSelector = dojo11.byId('who_' + getId[1]);
    whoSelector.style.display = 'none';
}

function showSyslogInput(el) {

    var syslogDivIn = dojo11.byId('sysloginput');
    syslogDivIn.style.display = '';
    dojo11.byId('metainput').focus();
}

function hideSyslogInput(el) {

    var syslogDivIn = dojo11.byId('sysloginput');
    syslogDivIn.style.display = 'none';
}

function showSnmpInput(el) {

    var snmpDivIn = dojo11.byId('snmpinput');
    snmpDivIn.style.display = '';
    dojo11.byId('snmpinput').focus();
}

function hideSnmpInput(el) {

    var snmpDivIn = dojo11.byId('snmpinput');
    snmpDivIn.style.display = 'none';
}


function onchange_time(el) {

    var writeTime = dojo11.byId('time');
    writeTime.style.display = "";
    var index = el.options[el.selectedIndex].value;
    writeTime.innerHTML = 'Then wait: ' + formatWaitTime(el, null, '<fmt:message key="alert.config.props.CB.Enable.TimeUnit.2"/>',  '<fmt:message key="alert.config.props.CB.Enable.TimeUnit.1"/>');
}

function hideDisplay() {
    $(emailinput).style.display = 'none';
    $(sysloginput).style.display = 'none';
}

function removeRow(obj) {
    var oTR = obj.parentNode.parentNode;
    var oTable = oTR.parentNode.parentNode;
    var oLi = oTable.parentNode;
    var root = oLi.parentNode;

    root.removeChild(oLi);
}

function addOption(sel, val, txt, selected) {
    var o = document.createElement('option');
    var t = document.createTextNode(txt);

    o.setAttribute('value', val);

    if (selected) {
        o.setAttribute('selected', 'true');
    }
    sel.appendChild(o);
    o.appendChild(document.createTextNode(txt));
}

function showResponse(originalRequest) {
    dojo11.byId('escMsg').innerHTML = "Escalation Saved";

}

function showResponseRemoved() {
    dojo11.byId('example').style.display = '';
    dojo11.byId('escMsg').innerHTML = "Action removed from this escalation";

    if (dojo11.byId('viewEscalationUL').firstChild) {
        dojo11.byId('noActions').style.display = "none";
    } else {
        dojo11.byId('noActions').style.display = "";
    }
}

function removeAction(id) {
    var urlBegin = '<html:rewrite action="/escalation/removeAction/';
        var urlEnd = '.do"/>';
    var url = urlBegin + id + urlEnd;

    var id = dojo11.byId('id').value;
    var pars = "EscId=" + id;

    new Ajax.Request(url, {method: 'post', parameters: pars, onComplete: showResponseRemoved, onFailure :reportError});
}

function configure(id) {
    var sel = dojo11.byId('who' + id);
    var selval = sel.options[sel.selectedIndex].value;

    if (selval == 'Users') {
        // Select checkboxes based on existing configs
        insertUsers(this.id);
    }
    else if (selval == 'Others') {
        // Set the inner text
        insertOthers(this.id);
    }
    else if (selval == 'Roles') {
        // Select checkboxes based on existing configs
        insertRoles(this.id);
    }
}

function configureOthers(el) {
    var idStr = el;
    var getId = idStr.split('_');
    var othersDivIn = dojo11.byId('othersDiv_' + getId[1]);

    Dialog.confirm(othersDivIn.innerHTML,
    {windowParameters: {className:'dialog', width:305, height:200,
        resize:false, draggable:false},
        okLabel: "OK", cancelLabel: "Cancel",
        ok:function(win) {
            // Do something
            new Effect.Shake(Windows.focusedWindow.getId());
            return true;
        }});
}

function configureUsers(el) {
    var idStr = el;
    var getId = idStr.split('_');
    var usersDivIn = dojo11.byId('usersDiv' + getId[1]);
    var writeListUsers = dojo11.byId('userListDisplay');

    Dialog.confirm('<div id="usersConfigWindow">' + usersDivIn.innerHTML +
                   '</div>',
    {windowParameters: {className:'dialog', width:305, height:200,
        resize:false, draggable:false},
        okLabel: "OK", cancelLabel: "Cancel",
        ok:function(win) {
            var usersInputList =
                    usersDivIn.getElementsByTagName('input');
            var updatedInputList =
                    dojo11.byId('usersConfigWindow').getElementsByTagName('input');

            writeListUsers.appendChild(document.createTextNode('Notify: '));

            for (i = 0; i < usersInputList.length; i++) {

                if (updatedInputList[i].checked) {
                    usersInputList[i].setAttribute("checked", "true");
                }

                if (usersInputList[i].checked) {
                    var checkedValues = usersInputList[i].value;

                <c:forEach var="user" items="${AvailableUsers}" varStatus="status">
                    if (checkedValues == <c:out value="${user.id}"/>) {
                        writeListUsers.appendChild(document.createTextNode('<c:out value="${user.name}" />, '));
                    }
                </c:forEach>

                }
            }
            new Effect.Fade(Windows.focusedWindow.getId())

            return true;
        }});
}

function configureRoles(el) {
    var idStr = el;
    var getId = idStr.split('_');
    var rolesDivIn = dojo11.byId('rolesDiv' + getId[1]);
    var writeListUsers = dojo11.byId('userListDisplay');

    Dialog.confirm('<div id="rolesConfigWindow">' + rolesDivIn.innerHTML +
                   '</div>',
    {windowParameters: {className:'dialog', width:305, height:200,
        resize:false, draggable:false},
        okLabel: "OK", cancelLabel: "Cancel",
        ok:function(win) {
            var rolesInputList =
                    rolesDivIn.getElementsByTagName('input');
            var updatedInputList =
                    dojo11.byId('rolesConfigWindow').getElementsByTagName('input');

            writeListUsers.appendChild(document.createTextNode('Notify: '));

            for (i = 0; i < rolesInputList.length; i++) {


                if (updatedInputList[i].checked) {
                    rolesInputList[i].setAttribute("checked", "true");
                }

                if (rolesInputList[i].checked) {
                    var checkedValues = rolesInputList[i].value;
                <c:forEach var="user" items="${AvailableRoles}" varStatus="status">
                    if (checkedValues == <c:out value="${user.id}"/>) {
                        writeListUsers.appendChild(document.createTextNode('<c:out value="${user.name}" />, '));
                    }
                </c:forEach>

                }
            }
            new Effect.Fade(Windows.focusedWindow.getId());
            return true;
        }});
}

function schemeChange(sel) {
    document.EscalationSchemeForm.escId.value = sel.options[sel.selectedIndex].value;
    document.EscalationSchemeForm.submit();
}

function reportError(originalRequest) {
    alert('Error ' + originalRequest.status + ' -- ' + originalRequest.statusText);
}


function hideExample() {
    dojo11.byId('example').style.display = 'none';
}

function cancelAddEscalation() {
    dojo11.byId('addEscalationUL').innerHTML = "";
    dojo11.byId('addEscButtons').style.display = "none";
    dojo11.byId('addRowButton').style.display = "";
}

function checkMeta() {

    var metaText = dojo11.byId('metainput').value;
    if (metaText == '') {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.noMetaInput"/>';
        dojo11.byId('metainput').focus();
        return false;

    } else {
        hideErrorDisplay();
        return true;
    }
}

function checkProduct() {

    var productText = dojo11.byId('productinput').value;
    if (productText == '') {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.noProductInput"/>';
        dojo11.byId('productinput').focus();
        return false;
    } else {
        hideErrorDisplay();
        return true;
    }
}

function checkVersion() {

    var versionText = dojo11.byId('versioninput').value;
    if (versionText == '') {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.noVersionInput"/>';
        dojo11.byId('versioninput').focus();
        return false;

    } else {
        hideErrorDisplay();
        return true;
    }
}

function checkIP() {

    var IPText = dojo11.byId('snmpIPinput').value;
    if (IPText == '') {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="admin.config.message.IncorrectSNMPIPFormat"/>';
        dojo11.byId('snmpIPinput').focus();
        return false;

    } else {
        hideErrorDisplay();
        return true;
    }
}


function checkOID() {
    var OIDText = dojo11.byId('snmpOIDinput').value;

    if (OIDText == '') {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="admin.config.message.IncorrectSNMPTrapOIDFormat"/>';
        dojo11.byId('snmpOIDinput').focus();
        return false;

    } else {
        hideErrorDisplay();
        return true;
    }
}


function checkEmail() {

    var emailTextArea = dojo11.byId('emailinput');
    var userListCheck = dojo11.byId('userListDisplay');
    var emailAdds = emailTextArea.value;
    var illegalChars = /[\(\)\<\>\;\:\\\/\"\'\[\]]/;

    if (selActionTypeEsc == "NoOp" || selActionTypeEsc == "Syslog" || selActionTypeEsc == "Select" || selActionTypeEsc == "SNMP") {
        return true;
    } else

            <%--
           var separatedEmails = emailAdds.split(',');
            for (i = 0; i < separatedEmails.length; i++) {
         
           if(!((separatedEmails[i].indexOf(".") > 2) && (separatedEmails[i].indexOf("@") > 0))) {
            dojo11.byId('example').style.display= '';
            dojo11.byId('example').setAttribute((document.all ? 'className' : 'class'), "ErrorBlock");
            dojo11.byId('okCheck').innerHTML = '<html:img page="/images/tt_error.gif" height="9" width="9" border="0" alt=""/>';
            dojo11.byId('escMsg').innerHTML ='<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.invalidEmailAddressFormat"/>';
            return false;
                }
            }
            --%>

        if (selUserEsc == 'Others' && emailAdds == '') {
            showErrorDisplay();
            dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.noUserSelected"/>';
            return false;
        } else if (emailAdds.match(illegalChars)) {
            showErrorDisplay();
            dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.invalidEmailAddressInput"/>'
            return false;
        } else {
            hideErrorDisplay();
            return true;
        }

}

function checkSMS() {

    if ((selActionTypeEsc == 'SMS') && selUserEsc == undefined) {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.noUserSelected"/>';
        return false;
    } else {
        hideErrorDisplay();
        return true;
    }
}

function textCounter(field, countfield, maxlimit) {
    if (field.value.length > maxlimit)
    {
        field.value = field.value.substring(0, maxlimit);
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.250Char"/>';
        return false;
    } else {
        hideErrorDisplay();
        return true;
    }
}

function showErrorDisplay() {
    dojo11.byId('example').style.display = '';
    dojo11.byId('example').setAttribute((document.all ? 'className' : 'class'), "ErrorBlock");
    dojo11.byId('okCheck').innerHTML = '<html:img page="/images/tt_error.gif" height="9" width="9" border="0" alt=""/>';
}

function hideErrorDisplay() {
    dojo11.byId('escMsg').innerHTML = '';
    dojo11.byId('example').style.display = 'none';
    dojo11.byId('addEscButtons').style.display = "";
}

function ActionTypeNull() {
    if (selActionTypeEsc == undefined || selActionTypeEsc == 'Select') {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.SelectEscMethod"/>';
        return false;
    } else {
        return true;
    }
}

function selUserEscNull() {
    var  userList = dojo11.byId('userListDisplay').innerHTML;
    if ((selUserEsc == undefined || selUserEsc == 'Select' || userList=='') && (selActionTypeEsc != "Syslog" && selActionTypeEsc != "SNMP" && selActionTypeEsc != "NoOp")) {
        showErrorDisplay();
        dojo11.byId('escMsg').innerHTML = '<fmt:message key="error.Error.Tab"/> ' + '<fmt:message key="alert.config.error.noUserSelected"/>';
        return false;
    } else {
        return true;
    }
}
        
function saveAddEscalation() {
    if (!ActionTypeNull()) {
        return false;
    }

    if (!selUserEscNull()) {
        return false;
    }

    if (selUserEsc == 'Others') {
        if (!checkEmail()) {
            return false;
        }
    }

    if (selActionTypeEsc == "SMS") {
        if (!checkSMS()) {
            return false;
        }
    }

    if (selActionTypeEsc == "SNMP") {
        if (!checkIP()) {
            return false;
        }
        if (!checkOID()) {
            return false;
        }
    }

    if (selActionTypeEsc == "Syslog") {
        if (!checkMeta()) {
            return false;
        }
        if (!checkProduct()) {
            return false;
        }
        if (!checkVersion()) {
            return false;
        }
    }


    var emailTextArea = dojo11.byId('emailinput');
    var emailAdds = emailTextArea.value;

    emailTextArea.value = emailAdds.split(/[\s]/);
    emailTextArea.value = emailAdds.split(/,/);


    var id = dojo11.byId('id').value;
    var serialAddAction = Form.serialize('addEscalation');
    var pars = "EscId=" + id + "&" + serialAddAction;
    var url = '<html:rewrite action="/escalation/saveAction"/>';

    new Ajax.Request(url, {method: 'post', parameters: pars, onComplete: updateEscView, onFailure: reportError});
    document.EscalationForm.reset();


}

</script>

<html:form action="/alerts/ConfigEscalation" method="GET">
    <html:hidden property="mode"/>
    <c:choose>
        <c:when test="${not empty param.ad}">
            <input type="hidden" id="ad" name="ad"
                   value='<c:out value="${param.ad}"/>'/>
        </c:when>
        <c:when test="${not empty param.gad}">
            <input type="hidden" id="gad" name="gad"
                   value='<c:out value="${param.gad}"/>'/>
        </c:when>
    </c:choose>
    <c:if test="${not empty alertDef}">
        <c:choose>
            <c:when test="${not empty Resource}">
                <html:hidden property="eid" value="${Resource.entityId}"/>
            </c:when>
            <c:otherwise>
                <html:hidden property="aetid" value="${ResourceType.appdefTypeKey}"/>
            </c:otherwise>
        </c:choose>
    </c:if>
    <html:hidden property="escId"/>
</html:form>

<div id="example" style="display:none;" class="ConfirmationBlock">
    <table width="100%" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td style="padding-right:5px;" id="okCheck">
                <html:img page="/images/tt_check.gif" height="9" width="9" border="0" alt=""/>
            </td>
            <td width="98%">
                <div id="escMsg"></div>
            </td>
        </tr>
    </table>
</div>

<div id="escError" style="display:none;">
<table width="100%" cellpadding="0" cellspacing="0" border="0">
  <td class="ErrorBlock" width="9">
    <html:img page="/images/tt_error.gif" height="9" width="9" border="0" alt=""/>
  </td>
  <td class="ErrorBlock" width="100%">
    <div id="errMsg"></div>
  </td>
</table>
</div>

<c:if test="${useroperations['modifyEscalation']}">
<div class="ListHeaderInactive"
     style="border: 1px solid rgb(213, 216, 222); margin-bottom: 10px; padding: 4px; font-weight: normal;">
     <fmt:message key="inform.config.escalation.scheme.inProgressEscalation"/>
</div>
</c:if>

<form action='<html:rewrite action="/escalation/saveEscalation"/>'
      name="EscalationForm" id="EscalationForm" onchange="hideExample();"><input
        type="hidden" value="0" id="pid"> <input type="hidden" value="0"
                                                 id="pversion"> <input type="hidden" value="0"
                                                                       id="if the escalation is new or not"> <input
        type="hidden" value="0"
        id="theValue">
<c:choose>
    <c:when test="${not empty Resource}">
        <html:hidden property="eid" value="${Resource.entityId}"/>
    </c:when>
    <c:otherwise>
        <html:hidden property="aetid" value="${ResourceType.appdefTypeKey}"/>
    </c:otherwise>
</c:choose>
<c:choose>
    <c:when test="${not empty param.ad}">
        <input type="hidden" id="ad" name="ad" value='<c:out value="${param.ad}"/>'/>
    </c:when>
    <c:when test="${not empty param.gad}">
        <input type="hidden" id="gad" name="gad"
               value='<c:out value="${param.gad}"/>'/>
    </c:when>
</c:choose>
<input type="hidden" id="ffff" name="ggg"
       value='<c:out value="${escalation.id}"/>'/> <input type="hidden" id="escId"
                                                          name="id"/>

<table width="100%" cellpadding="4" cellspacing="0" border="0"
       id="escPropertiesTable">
    <tbody>
        <tr>
            <td class="BlockTitle" colSpan="2">
                <fmt:message
                        key="alert.config.escalation.scheme"/>
            </td>
        </tr>
        <tr>
            <td class="BlockLabel" width="20%">
                <fmt:message
                        key="common.label.Name"/>
            </td>
            <td width="80%" id="name" class="BlockLabel" style="text-align:left"></td>
        </tr>
        <tr>
            <td class="BlockLabel" valign="top">
                <fmt:message
                        key="common.label.Description"/>
            </td>
            <td id="description" class="BlockContent"></td>
        </tr>
        <tr>
            <td class="BlockLabel" nowrap="true">
                <fmt:message
                        key="alert.config.escalation.acknowledged"/>
            </td>
            <td id="acknowledged" class="BlockContent"></td>
        </tr>
        <tr>
            <td class="BlockLabel" nowrap="true">
                <fmt:message
                        key="alert.config.escalation.state.change"/>
            </td>
            <td id="changed" class="BlockContent"></td>
        </tr>
        <tr>
            <td class="BlockLabel" nowrap="true">
                <fmt:message key="alert.config.escalation.state.ended"/>
            </td>
            <td id="ended" class="BlockContent"></td>
        </tr>
        <c:if test="${useroperations['modifyEscalation']}">
            <tr class="ToolbarContent">
                <!-- EDIT TOOLBAR -->
                <td colSpan="2">
                	<input type="button" id="button" value="<fmt:message key="common.label.Edit"/>" onclick="editEscalation(); return false;" style="color:#fff;font-weight:700;width:auto;overflow:visible;" />
                </td>
            </tr>
        </c:if>
    </tbody>
</table>

<table width="100%" cellpadding="3" cellspacing="0" border="0"
       id="editPropertiesTable" style="display: none;">
<tbody>
<tr>
    <td class="BlockTitle" colSpan="2">
        <fmt:message
                key="alert.config.escalation.scheme"/>
    </td>
</tr>
<tr>
    <td class="BlockContent">
        <table width="100%" cellpadding="4" cellspacing="0">
            <tr>
                <td class="BlockLabel" width="20%">
                    <fmt:message
                            key="common.label.Name"/>
                </td>
                <td width="80%"><input type="text" size="25" name="name"
                                       id="escName"/></td>
            </tr>
            <tr>
                <td class="BlockLabel" valign="top">
                    <fmt:message
                            key="common.label.Description"/>
                </td>
                <td><textarea cols="40" rows="4" name="description" id="escDesc"
                              onkeypress="textCounter(this,this.form.counter,250);"
                              onblur="textCounter(this,this.form.counter,250);"></textarea>
                </td>
            </tr>
        </table>
    </td>
</tr>
<tr>
    <td class="BlockTitle">
        <fmt:message
                key="alert.config.escalation.acknowledged"/>
    </td>
</tr>
<tr class="BlockContent">
    <td style="padding-left:15px;padding-bottom:10px;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0">
            <tbody>
                <tr>
                    <td style="padding-top:2px;padding-bottom:2px;">
						<span id="AlertEscalationOption"><input type="radio" name="allowPause" id="allowPauseTrue" value="true" onClick="this.value=true;"/>
                        <fmt:message key="alert.config.escalation.allow.pause"/>&nbsp;</span>
					</td>
                </tr>
                <tr>
                    <td style="padding-top:2px;padding-bottom:2px;"><input
                            type="radio" name="allowPause" id="allowPauseFalse" value="false"
                            checked="true"/>
                        <fmt:message
                                key="alert.config.escalation.allow.continue"/>
                    </td>
                </tr>
            </tbody>
        </table>
    </td>
</tr>
<tr>
    <td class="BlockTitle">
        <fmt:message
                key="alert.config.escalation.state.change"/>
        <br>
    </td>
</tr>
<tr class="BlockContent">
    <td style="padding-left:15px;padding-bottom:10px;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0">
            <tbody>

                <tr>
                    <td style="padding-top:2px;padding-bottom:2px;"><input
                            type="radio" name="notifyAll" id="notifyAllTrue" value="true"
                            onClick="this.value=true;"/>
                        <fmt:message
                                key="alert.config.escalation.state.change.notify.all"/>
                    </td>
                </tr>
                <tr>
                    <td style="padding-top:2px;padding-bottom:2px;"><input
                            type="radio" name="notifyAll" id="notifyAllFalse" value="false"
                            checked="true"/>
                        <fmt:message
                                key="alert.config.escalation.state.change.notify.previous"/>
                    </td>
                </tr>
            </tbody>
        </table>
    </td>
</tr>
<tr>
    <td class="BlockTitle">
        <fmt:message key="alert.config.escalation.state.ended"/>
        <br>
    </td>
</tr>
<tr class="BlockContent">
    <td style="padding-left:15px;padding-bottom:10px;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0">
            <tbody>
                <tr>
                    <td style="padding-top:2px;padding-bottom:2px;"><input
                            type="radio" name="repeat" id="repeatFalse" value="false"
                            checked="true"/>
                        <fmt:message key="alert.config.escalation.state.ended.stop"/>
                    </td>
                </tr>
               <tr>
                    <td style="padding-top:2px;padding-bottom:2px;"><input
                            type="radio" name="repeat" id="repeatTrue" value="true"
                            onClick="this.value=true;"/>
                        <fmt:message key="alert.config.escalation.state.ended.repeat"/>
                    </td>
                </tr>
            </tbody>
        </table>
    </td>
</tr>
<tr class="ToolbarContent">
    <!-- SET TOOLBAR -->
    <td>
        <table cellspacing="4" cellpadding="0">
            <tr>
                <td>
                	<input type="button" id="button" value="<fmt:message key="common.label.Save"/>" onclick="saveEscalation(); return false;" style="color:#fff;font-weight:700;width:auto;overflow:visible;" />
                </td>
                <td>
                	<input type="button" id="button" value="<fmt:message key="common.label.Cancel"/>" onclick="cancelEditEscalation(); return false;" style="color:#fff;font-weight:700;width:auto;overflow:visible;" />
                </td>
            </tr>
        </table>
    </td>
</tr>
</tbody>
</table>

<script type="text/javascript">
  var escalationSpan = dojo11.byId("AlertEscalationOption");
  if (escalationSpan != null) {
	  escalationSpan.appendChild(hyperic.form.createEscalationPauseOptions({id: "maxWaitTime", name: "maxWaitTime", className:"maxWaitTime"}));
  }
</script>

<div id="usersList" style="display:none;">
    <div class="ListHeader">Select Users</div>
    <ul class="boxy">
        <c:forEach var="user" items="${AvailableUsers}" varStatus="status">
            <li class="BlockContent"><input type="checkbox" name="users"
                                            value="<c:out value="${user.id}"/>">
                    <c:out
                            value="${user.name}"/>
            </input></li>
        </c:forEach>
    </ul>
</div>
<c:if test="${not empty AvailableRoles}">
    <div id="rolesList" style="display: none;">
        <div class="ListHeader">Select Roles</div>
        <ul class="boxy">
            <c:forEach var="role" items="${AvailableRoles}" varStatus="status">
                <li class="BlockContent"><input type="checkbox" name="roles"
                                                value="<c:out value="${role.id}"/>">
                        <c:out
                                value="${role.name}"/>
                </input></li>
            </c:forEach>
        </ul>
    </div>
</c:if>
</form>

<br/>

<form name="viewEscalation" id="viewEscalation">
    <input type="hidden" id="alertDefId" name="alertDefId" value='<c:out value="${alertDef.id}"/>'/>
    <input type="hidden" value="" id="creationTime">
    <input type="hidden" value="" id="_version_">
    <input type="hidden" value="" id="notifyAll">
    <input type="hidden" value="" id="modifiedTime">
    <input type="hidden" value="" id="allowPause">
    <input type="hidden" value="" id="escName">
    <input type="hidden" value="" id="id">
    <input type="hidden" value="" id="repeat">

	<div>
		<div class="BlockTitle" style="position:relative;">
			<span id="step2create" style="display:none;">Step 2 - Create </span>
            <fmt:message key="common.label.EscalationSchemeActions"/>
			<html:img page="/images/icon_info.gif"
			          style="position:absolute;right:3px;"
                      onmouseover="menuLayers.show('actionsInfoPopup', event)"
                      onmouseout="menuLayers.hide()" border="0"/>
        </div>
        <div id="pauseTimeText"></div>
        <div class="BlockContent" id="noActions" style="padding:5px;display:none;">
        	<b><fmt:message key="inform.config.escalation.scheme.newAction.noactions"/></b>
        </div>
        <div id="viewSection" style="display:none;">
        	<ul id="viewEscalationUL" style="margin-left:0px;"></ul>
        </div>
    </div>
</form>
<form name="addEscalation" id="addEscalation" style="position: relative;">
	<div style="position: absolute;top:0px;left:0px;width:100%;background-color:#fff;padding-top:3px;">
		<div id="addSection">
			<ul id="addEscalationUL" style="margin-left:0px;"></ul>
		</div>
		<c:if test="${useroperations['createEscalation'] || useroperations['modifyEscalation']}">
			<div class="ToolbarContent" id="addRowButton">
				<input type="button" 
				       id="button" 
				       value="<fmt:message key="common.label.AddAction"/>" 
				       onclick="addRow(); return false;" 
				       style="color:#fff;font-weight:700;width:auto;overflow:visible;" />
			</div>
		</c:if>
		<div id="addEscButtons" class="ToolbarContent" style="display:none">
        	<span id="saveButton">
				<input type="button" 
				       id="button" 
				       value="<fmt:message key="common.label.Save"/>"
                       onclick="saveAddEscalation(); return false;" 
                       style="color:#fff;font-weight:700;width:auto;overflow:visible;" />
            </span>
            <span>
				<input type="button" 
				       id="button" 
				       value="<fmt:message key="common.label.Cancel"/>" 
				       onclick="cancelAddEscalation(); return false;" 
				       style="color:#fff;font-weight:700;width:auto;overflow:visible;" />
            </span>
		</div>
	</div>
</form>
<div id="actionsInfoPopup" class="menu" style="padding:3px;">
    <fmt:message
            key="inform.config.escalation.scheme.newAction.dragaction"/>
</div>