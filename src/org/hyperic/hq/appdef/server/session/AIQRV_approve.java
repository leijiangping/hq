/*
 * NOTE: This copyright does *not* cover user programs that use HQ
 * program services by normal system calls through the application
 * program interfaces provided as part of the Hyperic Plug-in Development
 * Kit or the Hyperic Client Development Kit - this is merely considered
 * normal use of the program, and does *not* fall under the heading of
 * "derived work".
 * 
 * Copyright (C) [2004, 2005, 2006], Hyperic, Inc.
 * This file is part of HQ.
 * 
 * HQ is free software; you can redistribute it and/or modify
 * it under the terms version 2 of the GNU General Public License as
 * published by the Free Software Foundation. This program is distributed
 * in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 * USA.
 */

package org.hyperic.hq.appdef.server.session;

import java.util.List;

import javax.ejb.CreateException;

import org.hyperic.hq.appdef.shared.AIConversionUtil;
import org.hyperic.hq.appdef.shared.AIIpValue;
import org.hyperic.hq.appdef.shared.AIPlatformValue;
import org.hyperic.hq.appdef.shared.AIQApprovalException;
import org.hyperic.hq.appdef.shared.AIQueueConstants;
import org.hyperic.hq.appdef.shared.AIServerValue;
import org.hyperic.hq.appdef.shared.AppdefEntityConstants;
import org.hyperic.hq.appdef.shared.AppdefEntityID;
import org.hyperic.hq.appdef.shared.CPropManagerLocal;
import org.hyperic.hq.appdef.shared.ConfigManagerLocal;
import org.hyperic.hq.appdef.shared.IpValue;
import org.hyperic.hq.appdef.shared.PlatformManagerLocal;
import org.hyperic.hq.appdef.shared.PlatformNotFoundException;
import org.hyperic.hq.appdef.shared.PlatformValue;
import org.hyperic.hq.appdef.shared.ServerLightValue;
import org.hyperic.hq.appdef.shared.ServerManagerLocal;
import org.hyperic.hq.appdef.shared.ServerNotFoundException;
import org.hyperic.hq.appdef.shared.ServerValue;
import org.hyperic.hq.appdef.shared.ValidationException;
import org.hyperic.hq.authz.shared.AuthzSubjectValue;
import org.hyperic.hq.authz.shared.PermissionException;
import org.hyperic.hq.common.ApplicationException;
import org.hyperic.hq.common.SystemException;
import org.hyperic.hq.autoinventory.AIPlatform;
import org.hyperic.hq.autoinventory.AIIp;
import org.hyperic.hq.autoinventory.AIServer;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * The AIQueueConstants.Q_DECISION_APPROVE means to add the queued
 * resource to the appdef model.  This visitor merges the queued resource
 * into appdef.
 */
public class AIQRV_approve implements AIQResourceVisitor {

    private static Log _log = LogFactory.getLog(AIQRV_approve.class);
    private PlatformValue existingPlatformValue = null;

    public AIQRV_approve () {}

    public void visitPlatform(AIPlatform aiplatform,
                              AuthzSubjectValue subject,
                              PlatformManagerLocal pmLocal,
                              ConfigManagerLocal configMgr,
                              CPropManagerLocal cpropMgr,
                              List createdResources)
        throws AIQApprovalException, PermissionException {

        Integer id = aiplatform.getId();
        
        _log.info("Visiting platform: " + id +
                  " fqdn=" + aiplatform.getFqdn());

        // Clear out previous platform
        existingPlatformValue = null;
        
        AIPlatformValue aiplatformValue = aiplatform.getAIPlatformValue();
        PlatformValue existingPlatform;
        PlatformValue newPlatformValue;
        AppdefEntityID appdefEntityId;

        int qstat = aiplatform.getQueueStatus();
        switch (qstat) {
        case AIQueueConstants.Q_STATUS_PLACEHOLDER:
            // We don't approve placeholders.  Just let them sit
            // in the queue.
            break;

        case AIQueueConstants.Q_STATUS_ADDED:
            // This platform exists in the queue but not in appdef,
            // so add it to appdef.
            existingPlatform =
                getExistingPlatformValue(subject, pmLocal, aiplatformValue);

            if (existingPlatform != null) {
                appdefEntityId =
                    new AppdefEntityID(AppdefEntityConstants.
                                       APPDEF_TYPE_AIPLATFORM, id);
                _log.error("Platform already added: platformid="
                           + existingPlatform.getId() + ", "
                           + "cannot approve AIPlatform " + id);
                throw new AIQApprovalException(appdefEntityId, 
                                               AIQApprovalException.
                                               ERR_ADDED_TO_APPDEF);
            }

            // Add the AI platform to appdef
            _log.info("Calling platform create...");
            try {
                Integer pk =
                    pmLocal.createPlatform(subject, aiplatformValue);
                try {
                    newPlatformValue =
                        pmLocal.getPlatformById(subject, pk);

                    appdefEntityId = new AppdefEntityID(
                            AppdefEntityConstants.APPDEF_TYPE_PLATFORM,
                            newPlatformValue.getId());
                } catch (PlatformNotFoundException e) {
                    throw new SystemException("Could not find the platform " +
                                              "we just created: " + pk);
                }

                setCustomProperties(aiplatform,
                                    newPlatformValue, cpropMgr);

                createdResources.add(appdefEntityId);
            } catch (PermissionException e) {
                throw e;
            }
            catch (ValidationException e) {
                throw new SystemException("Error creating platform from " +
                                          "AI data.", e);
            }
            catch (ApplicationException e) {
                appdefEntityId =
                    new AppdefEntityID(AppdefEntityConstants.
                                       APPDEF_TYPE_AIPLATFORM, id);
                throw new AIQApprovalException(appdefEntityId, e.getMessage());
            }
            // catch create exception if duplicate AI platform gets imported
            // at the same time.  If we find that there are other cases,
            // which causes the create exception, then we have to look at more
            // details.
            catch (CreateException e) {
                // check if this create exception is caused by an existing
                // platform.
                existingPlatform =
                    getExistingPlatformValue(subject, pmLocal, aiplatformValue);
                
                if (existingPlatform != null) {
                    appdefEntityId =
                        new AppdefEntityID(AppdefEntityConstants.
                                           APPDEF_TYPE_AIPLATFORM, id);
                    _log.error("Platform already added: platformid="
                               + existingPlatform.getId() + ", "
                               + "cannot approve AIPlatform " + id);
                    throw new AIQApprovalException(appdefEntityId, 
                                                   AIQApprovalException.
                                                   ERR_ADDED_TO_APPDEF);
                } else {
                    throw new SystemException("Error creating platform from "
                                               + "AI data.", e);
                }
            }
            
            if (aiplatformValue.isPlatformDevice()) {
                try {
                    AIConversionUtil.
                        configurePlatform(subject,
                                          existingPlatformValue.getId(),
                                          aiplatform.getProductConfig(),
                                          aiplatform.getMeasurementConfig(),
                                          aiplatform.getControlConfig(),
                                          null, true, configMgr);
                } catch (Exception e) {
                    _log.warn("Error configuring platform: " + e, e);
                }
            }
            _log.info("Created platform (" + aiplatformValue.getId() + "): "
                      + aiplatformValue);
            break;

        case AIQueueConstants.Q_STATUS_CHANGED:
            // This platform exists in the queue and in appdef.
            // We wish to sync the appdef attributes to match
            // the queue.
            
            // Check to make sure the platform is still in appdef.

            // Update existing platform attributes.
            _log.info("Updating platform...");
            try {
                pmLocal.updateWithAI(aiplatformValue, subject.getName());
            } catch (PlatformNotFoundException e) {
                // If it has been removed, that's an error.
                appdefEntityId = new AppdefEntityID(
                        AppdefEntityConstants.APPDEF_TYPE_AIPLATFORM,
                        id);
                _log.error("Platform removed from appdef, " +
                           "cannot approve AIPlatform " + id);
                throw new AIQApprovalException(appdefEntityId,
                        AIQApprovalException.ERR_REMOVED_FROM_APPDEF);
            } catch (Exception e) {
                throw new SystemException("Error updating platform using "
                                             + "AI data.", e);
            }

            existingPlatform =
                getExistingPlatformValue(subject, pmLocal, aiplatformValue);
            setCustomProperties(aiplatform, existingPlatform, cpropMgr);

            if (aiplatformValue.isPlatformDevice()) {
                try {
                    AIConversionUtil.
                        configurePlatform(subject,
                                          existingPlatform.getId(),
                                          aiplatform.getProductConfig(),
                                          aiplatform.getMeasurementConfig(),
                                          aiplatform.getControlConfig(),
                                          null, true, configMgr);
                } catch (Exception e) {
                    _log.warn("Error configuring platform: " + e, e);
                }
            }
            _log.info("Appdef platform updated.");
            break;

        case AIQueueConstants.Q_STATUS_REMOVED:
            // This platform has been removed (in other words, AI no longer
            // detects it) however it is still present in the appdef model.
            // We wish to remove the appdef platform.

            // If the platform has already been removed, do nothing.
            existingPlatform =
                getExistingPlatformValue(subject, pmLocal, aiplatformValue);

            if ( existingPlatform == null ) {
                _log.warn("Platform has already been removed, cannot " +
                          "remove aiplatform=" + id);
                return;
            }

            // Remove the platform, the 'true' here mean a 
            // deep/recursive removal.
            try {
                pmLocal.removePlatform(subject, existingPlatform.getId(), true);
            } catch (PermissionException e) {
                throw e;
            } catch (Exception e) {
                throw new SystemException("Error removing platform using " +
                                          "AI data.", e);
            }
            break;

        default:
            _log.error("Unknown queue state: " + qstat);
            throw new SystemException("Unknown queue state: " + qstat);
        }
    }

    public void visitIp(AIIp aiip,
                        AuthzSubjectValue subject,
                        PlatformManagerLocal pmLocal)
        throws AIQApprovalException, PermissionException
    {
        Integer id = aiip.getId();

        _log.info("Visiting ip: " + id + " addr=" + aiip.getAddress());

        AIPlatform aiplatform;
        AIPlatformValue aiplatformValue;
        IpValue ipValue;
        IpValue[] ipValues;
        AIIpValue aiipValue;
        boolean foundIp;
        int i;
        AppdefEntityID appdefEntityId;

        // Get the aiplatform for this ip
        aiplatform = aiip.getAIPlatform();
        aiplatformValue = aiplatform.getAIPlatformValue();
        existingPlatformValue =
            getExistingPlatformValue(subject, pmLocal, aiplatformValue);

        int qstat = aiip.getQueueStatus();
        switch (qstat) {
        case AIQueueConstants.Q_STATUS_PLACEHOLDER:
            // We don't approve placeholders.  Just let them sit
            // in the queue.
            break;

        case AIQueueConstants.Q_STATUS_ADDED:
            // This ip exists in the queue but not in appdef,
            // so add it to appdef.

            // If the platform does not exist in appdef, throw an exception
            if (existingPlatformValue == null) {
                appdefEntityId =
                    new AppdefEntityID(AppdefEntityConstants.APPDEF_TYPE_AIIP,
                                       id);
                _log.error("Ip cannot be approved: aiip=" + id + ", " +
                           "because platform doesn't yet exist " +
                           "in appdef: aiplatform=" + aiplatform.getId());
                throw new AIQApprovalException(appdefEntityId,
                                               AIQApprovalException.
                                               ERR_PARENT_NOT_APPROVED);
            }

            // Before we add it, make sure it's not already there...
            ipValues = existingPlatformValue.getIpValues();
            for ( i=0; i<ipValues.length; i++ ) {
                if ( ipValues[i].getAddress().equals(aiip.getAddress()) ) {
                    // already added, throw exception
                    appdefEntityId = new AppdefEntityID(AppdefEntityConstants.
                                                        APPDEF_TYPE_AIIP, id);
                    _log.error("IP already added: ipid="
                              + ipValues[i].getId() + ", "
                              + "cannot approve AIIp " + id);
                    throw new AIQApprovalException(appdefEntityId, 
                                                   AIQApprovalException.
                                                   ERR_ADDED_TO_APPDEF);
                }
            }

            // Add the AI ip to appdef
            _log.info("Calling update with new IP...");
            try {
                ipValue = AIConversionUtil.convertAIIpToIp(aiip.getAIIpValue());
                existingPlatformValue.addIpValue(ipValue);
                existingPlatformValue 
                    = pmLocal.updatePlatform(subject, existingPlatformValue);

            } catch (PermissionException e) {
                throw e;
            } catch (Exception e) {
                throw new SystemException("Error creating platform from " +
                                          "AI data.", e);
            }
            _log.info("Added ip (" + id + "): " + ipValue);
            break;

        case AIQueueConstants.Q_STATUS_CHANGED:
            // This ip exists in the queue and in appdef.
            // We wish to sync the appdef attributes to match
            // the queue.

            // Check to make sure the platform and ip are still in appdef.
            // If it has been removed, that's an error.
            if (existingPlatformValue == null) {
                appdefEntityId =
                    new AppdefEntityID(AppdefEntityConstants.APPDEF_TYPE_AIIP,
                                       id);
                _log.error("IP removed from appdef, " +
                           "cannot approve ip " + id);
                throw new AIQApprovalException(appdefEntityId, 
                                               AIQApprovalException.
                                               ERR_PARENT_REMOVED);
            }

            // Find the ip within the platform
            ipValues = existingPlatformValue.getIpValues();
            existingPlatformValue.removeAllIpValues();
            foundIp = false;
            for (i=0; i<ipValues.length; i++) {
                if (ipValues[i].getAddress().equals(aiip.getAddress())) {
                    aiipValue = aiip.getAIIpValue();
                    ipValues[i] = AIConversionUtil.mergeAIIpIntoIp(aiipValue,
                                                                   ipValues[i]);
                    foundIp = true;
                }
                existingPlatformValue.addIpValue(ipValues[i]);
            }
            if (!foundIp) {
                appdefEntityId = new AppdefEntityID(AppdefEntityConstants.APPDEF_TYPE_AIIP,
                                                    id);
                _log.error("IP removed from appdef, " +
                           "cannot approve AIIp " + id);
                throw new AIQApprovalException(appdefEntityId, 
                                               AIQApprovalException.ERR_REMOVED_FROM_APPDEF);
            }
            _log.info("Calling update IP...");

            try {
                existingPlatformValue 
                    = pmLocal.updatePlatform(subject, existingPlatformValue);
            } catch (PermissionException e) {
                throw e;
            } catch (Exception e) {
                throw new SystemException("Error updating platform with " +
                                          "new AIIp data.", e);
            }
            break;

        case AIQueueConstants.Q_STATUS_REMOVED:
            // This ip has been removed (in other words, AI no longer
            // detects it) however it is still present in the appdef model.
            // We wish to remove the appdef ip.

            // If the platform has already been removed, do nothing.
            if (existingPlatformValue == null) {
                _log.warn("Platform has already been removed, cannot " +
                          "remove aiip=" + id);
                return;
            }

            // Find the ip within the platform
            ipValues = existingPlatformValue.getIpValues();
            existingPlatformValue.removeAllIpValues();
            foundIp = false;
            for (i=0; i<ipValues.length; i++) {
                if (ipValues[i].getAddress().equals(aiip.getAddress())) {
                    foundIp = true;
                    existingPlatformValue.removeIpValue(ipValues[i]);
                } else {
                    existingPlatformValue.addIpValue(ipValues[i]);
                }
            }
            if (!foundIp) {
                // Ip has already been removed, return.
                _log.warn("IP has already been removed, cannot "
                          + "remove aiip=" + id);
            }

            _log.info("Calling remove IP...");
            try {
                existingPlatformValue 
                    = pmLocal.updatePlatform(subject, existingPlatformValue);
            } catch (PermissionException e) {
                throw e;
            } catch (Exception e) {
                throw new SystemException("Error updating platform to remove" +
                                          " ip, using AIIp data.", e);
            }
            break;

        default:
            _log.error("Unknown queue state: " + qstat);
            throw new SystemException("Unknown queue state: " + qstat);
        }
    }

    public void visitServer(AIServer aiserver,
                            AuthzSubjectValue subject,
                            PlatformManagerLocal pmLocal,
                            ServerManagerLocal smLocal,
                            ConfigManagerLocal configMgr,
                            CPropManagerLocal cpropMgr,
                            List createdResources)
        throws AIQApprovalException, PermissionException
    {
        Integer id = aiserver.getId();

        _log.info("Visiting server: " + id + " AIID=" +
                  aiserver.getAutoinventoryIdentifier());
        
        AIPlatform aiplatform;
        AIPlatformValue aiplatformValue;
        PlatformValue existingPlatformValue;
        ServerLightValue serverLightValue = null;
        ServerLightValue[] serverValues;
        AIServerValue aiserverValue;
        ServerValue serverValue = null;
        boolean foundServer;
        int i;
        AppdefEntityID appdefEntityId;
        Integer serverTypePK;

        // Get the aiplatform for this server
        aiplatform = aiserver.getAIPlatform();
        aiplatformValue = aiplatform.getAIPlatformValue();
        existingPlatformValue =
            getExistingPlatformValue(subject, pmLocal, aiplatformValue);

        int qstat = aiserver.getQueueStatus();
        switch (qstat) {
        case AIQueueConstants.Q_STATUS_PLACEHOLDER:
            // We don't approve placeholders.  Just let them sit
            // in the queue.
            break;

        case AIQueueConstants.Q_STATUS_ADDED:
            // This server exists in the queue but not in appdef,
            // so add it to appdef.

            // If the platform does not exist in appdef, throw an exception
            if ( existingPlatformValue == null ) {
                appdefEntityId =
                    new AppdefEntityID(AppdefEntityConstants.
                                       APPDEF_TYPE_AISERVER, id);
                _log.error("Server cannot be approved: aiserver=" + id + ", " +
                           "because platform doesn't yet exist " +
                           "in appdef: aiplatform=" + aiplatform.getId());
                throw new AIQApprovalException(appdefEntityId,
                                               AIQApprovalException.
                                               ERR_PARENT_NOT_APPROVED);
            }

            // Before we add it, make sure it's not already there...
            serverValues = existingPlatformValue.getServerValues();
            for ( i=0; i<serverValues.length; i++ ) {
                if (serverValues[i].getAutoinventoryIdentifier().
                    equals(aiserver.getAutoinventoryIdentifier()) ) {
                    // already added, throw exception
                    appdefEntityId = new AppdefEntityID(AppdefEntityConstants.
                                                        APPDEF_TYPE_AISERVER,
                                                        id);
                    _log.error("Server already added: serverid=" +
                               serverValues[i].getId() + ", " +
                               "cannot approve AIServer " + id);
                    throw new AIQApprovalException(appdefEntityId, 
                                                   AIQApprovalException.
                                                   ERR_ADDED_TO_APPDEF);
                }
            }

            // Add the AI server to appdef
            _log.info("Creating server...");
            try {
                serverValue = AIConversionUtil.
                    convertAIServerToServer(aiserver.getAIServerValue(),
                                            smLocal);
                serverTypePK = serverValue.getServerType().getId();
                Integer pk = smLocal.createServer(subject,
                                                  existingPlatformValue.getId(),
                                                  serverTypePK,
                                                  serverValue);
                try {
                    serverValue = smLocal.getServerById(subject, pk);
                } catch (ServerNotFoundException e) {
                    throw new SystemException("Could not find the server we" +
                                              " just created");
                }

                AppdefEntityID aID =
                    new AppdefEntityID(AppdefEntityConstants.APPDEF_TYPE_SERVER,
                                       pk);

                try {
                    AIConversionUtil.
                        configureServer(subject,
                                        serverValue.getId(),
                                        aiserver.getProductConfig(),
                                        aiserver.getMeasurementConfig(),
                                        aiserver.getControlConfig(),
                                        null,
                                        true,
                                        configMgr);
                } catch (Exception configE) {
                    _log.warn("Error configuring server: " + configE, configE);
                }

                setCustomProperties(aiserver, serverValue, cpropMgr);
                
                createdResources.add(aID);
            } catch ( PermissionException e ) {
                throw e;
            } catch ( Exception e ) {
                throw new SystemException("Error creating platform from " +
                                          "AI data: " + e.getMessage(), e);
            }
            _log.info("Created server (" + serverValue.getId() + "): " +
                      serverValue);
            break;

        case AIQueueConstants.Q_STATUS_CHANGED:
            // This server exists in the queue and in appdef.
            // We wish to sync the appdef attributes to match
            // the queue.

            // Check to make sure the platform and server are still in appdef.
            // If it has been removed, that's an error.
            if (existingPlatformValue == null) {
                appdefEntityId =
                    new AppdefEntityID(AppdefEntityConstants.
                                       APPDEF_TYPE_AISERVER, id);
                _log.error("Platform removed from appdef, " +
                           "cannot approve server " + id);
                throw new AIQApprovalException(appdefEntityId, 
                                               AIQApprovalException.
                                               ERR_PARENT_REMOVED);
            }

            // Find the server within the platform
            serverValues = existingPlatformValue.getServerValues();
            foundServer = false;
            for (i=0; i<serverValues.length; i++) {
                if (serverValues[i].getAutoinventoryIdentifier()
                    .equals(aiserver.getAutoinventoryIdentifier())) {
                    aiserverValue = aiserver.getAIServerValue();
                    try {
                        serverValue
                            = smLocal.findServerById(subject, 
                                                     serverValues[i].getId());
                    } catch (Exception e) {
                        throw new SystemException("Error fetching server " +
                                                  "with id=" +
                                                  serverValues[i].getId() +
                                                  ": " + e, e);
                    }
                    serverValue = AIConversionUtil.
                        mergeAIServerIntoServer(aiserverValue, serverValue);
                    foundServer = true;
                }
            }
            if (!foundServer) {
                appdefEntityId = new AppdefEntityID(AppdefEntityConstants.
                                                    APPDEF_TYPE_AISERVER, id);
                _log.error("Server removed from appdef, " +
                           "cannot approve AIServer " + id);
                throw new AIQApprovalException(appdefEntityId, 
                                               AIQApprovalException.
                                               ERR_REMOVED_FROM_APPDEF);
            }

            _log.info("Updating server...");
            try {
                serverValue = smLocal.updateServer(subject, 
                                                   serverValue);
                try {
                    AIConversionUtil.
                        configureServer(subject,
                                        serverValue.getId(),
                                        aiserver.getProductConfig(),
                                        aiserver.getMeasurementConfig(),
                                        aiserver.getControlConfig(),
                                        null, true,
                                        configMgr);
                } catch (Exception configE) {
                    _log.warn("Error configuring server: " + configE, configE);
                }

                setCustomProperties(aiserver, serverValue, cpropMgr);
            } catch (PermissionException e) {
                throw e;
            } catch (Exception e) {
                throw new SystemException("Error updating platform with " +
                                          "new AIServer data.", e);
            }
            _log.info("Updated server (" + serverValue.getId() + "): " +
                      serverValue);
            break;

        case AIQueueConstants.Q_STATUS_REMOVED:
            // This server has been removed (in other words, AI no longer
            // detects it) however it is still present in the appdef model.
            // We wish to remove the appdef platform.

            // If the platform has already been removed, do nothing.
            if (existingPlatformValue == null) {
                _log.warn("Platform has already been removed, cannot " +
                          "remove aiserver=" + id);
                return;
            }

            // Find the server within the platform
            serverValues = existingPlatformValue.getServerValues();
            foundServer = false;
            for (i=0; i<serverValues.length; i++) {
                if (serverValues[i].getAutoinventoryIdentifier().
                    equals(aiserver.getAutoinventoryIdentifier())) {
                    foundServer = true;
                    serverLightValue = serverValues[i];
                }
            }
            if (!foundServer) {
                // Server has already been removed, return.
                _log.warn("Server has already been removed, cannot " +
                          "remove aiserver=" + id);
            }
            _log.info("Removing Server...");
            try {
                smLocal.removeServer(subject, serverLightValue.getId(), true);
            } catch (PermissionException e) {
                throw e;
            } catch (Exception e) {
                throw new SystemException("Error updating platform to remove" +
                                          " server, using AIServer data.", e);
            }
            break;

        default:
            _log.error("Unknown queue state: " + qstat);
            throw new SystemException("Unknown queue state: " + qstat);
        }
    }

    private PlatformValue getExistingPlatformValue(AuthzSubjectValue subject, 
                                                   PlatformManagerLocal pmLocal,
                                                   AIPlatformValue aiplatform) {
        if (existingPlatformValue == null) {
            try {
                existingPlatformValue =
                    pmLocal.getPlatformByAIPlatform(subject, aiplatform);
            } catch (PermissionException e) {
                throw new SystemException(e);
            }
        }
        return existingPlatformValue;
    }

    private static void setCustomProperties(AIPlatform aiplatform,
                                            PlatformValue platform,
                                            CPropManagerLocal cpropMgr) {
        try {
            int typeId =
                platform.getPlatformType().getId().intValue();
            cpropMgr.setConfigResponse(platform.getEntityId(),
                                       typeId,
                                       aiplatform.getCustomProperties());
        } catch (Exception e) {
            _log.warn("Error setting platform custom properties: " + e, e);
        }
    }

    private static void setCustomProperties(AIServer aiserver,
                                            ServerValue server,
                                            CPropManagerLocal cpropMgr) {
        try {
            int typeId =
                server.getServerType().getId().intValue();
            cpropMgr.setConfigResponse(server.getEntityId(),
                                       typeId,
                                       aiserver.getCustomProperties());
        } catch (Exception e) {
            _log.warn("Error setting server custom properties: " + e, e);
        }
    }
}
