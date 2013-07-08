package org.hyperic.hq.plugin.system;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Set;

import org.hyperic.hq.appdef.shared.AIServiceValue;
import org.hyperic.hq.product.HypericOperatingSystem;
import org.hyperic.sigar.Sigar;
import org.hyperic.sigar.SigarException;
import org.hyperic.sigar.win32.Pdh;
import org.hyperic.sigar.win32.Win32Exception;
import org.hyperic.util.config.ConfigResponse;
import org.hyperic.util.config.EncodingException;
    
import com.ibm.icu.util.StringTokenizer;

public class HypervDetector extends   SystemServerDetector  {

    @Override
    protected String getServerType() {
        return SystemPlugin.HYPERV_SERVER_NAME;
    }
    
    protected ArrayList<AIServiceValue> getHyperVServices(String propertySet, String type, String namePrefix, String token, boolean toLower) {
        ArrayList<AIServiceValue> services = new ArrayList<AIServiceValue>();
        log.error("discoverServices");
        try {
            String[] instances = Pdh.getInstances(propertySet);
            log.error("num of instances found=" + instances.length);
            
            Set<String> names = new HashSet<String>();
            for (int i = 0; i < instances.length; i++) {
                log.error("instance=" +  instances[i]);
                String instance = instances[i];
                if ("_Total".equals(instance) || "<All instances>".equals(instance)) {
                    continue;
                }
                StringTokenizer st = new StringTokenizer(instance,token);
                String name = (String) st.nextElement();
                names.add(name);                
            }
            
            for (String name:names) {
                // add?"lfsdl;
                String info = namePrefix + name;
                AIServiceValue svc = 
                    createSystemService(type,
                                         getFullServiceName(info));

                try {
                    ConfigResponse cprops = new ConfigResponse();
                    svc.setCustomProperties(cprops.encode());
                    ConfigResponse conf = new ConfigResponse();
                    
                    log.error("name=<" + name + ">");                    
                    conf.setValue("instance.name", name);
                    conf.setValue(propertySet, name);
                    svc.setProductConfig(conf.encode());
                    svc.setMeasurementConfig(ConfigResponse.EMPTY_CONFIG);
                    
                } catch (EncodingException e) {
                    
                }
                                       
                 services.add(svc);
            
            }
            if (services.isEmpty()) {
                log.error("no servers found");
                return null;
            }
            return services;
        } catch (Win32Exception e) {
            log.debug("Error getting pdh data for " + propertySet + ": " + e, e);
            return null;
        }
    }

    @Override
    protected ArrayList<AIServiceValue> getSystemServiceValues(Sigar sigar, ConfigResponse config) throws SigarException {
        if (!HypericOperatingSystem.IS_HYPER_V) {
            return null;
        }
        ArrayList<AIServiceValue>  services = new ArrayList<AIServiceValue>();
        
        ArrayList<AIServiceValue> netServices = getHyperVServices(SystemPlugin.PROP_HYPERV_NETWORK_INTERFACE, SystemPlugin.HYPERV_NETWORK_INTERFACE, "Network Interface - ","", false);
        if (netServices!=null&&!netServices.isEmpty()) {
            services.addAll(netServices);
        }

        
        ArrayList<AIServiceValue> diskServices = getHyperVServices(SystemPlugin.PROP_HYPERV_PHYSICAL_DISK, SystemPlugin.HYPERV_PHYSICAL_DISK, "PhysicalDisk - ","", true);
        if (diskServices!=null&&!diskServices.isEmpty()) {
            services.addAll(diskServices);
        }
        
        ArrayList<AIServiceValue> logicalProcessorServices = getHyperVServices(SystemPlugin.PROP_HYPERV_LOGICAL_PROCESSOR, SystemPlugin.HYPERV_LOGICAL_PROCESSOR, "Logical Processor - ","", false);
        if (logicalProcessorServices!=null&&!logicalProcessorServices.isEmpty()) {
            services.addAll(logicalProcessorServices);
        }
        
        AIServiceValue memoryServices = getHyperVMemoryService();
        if (memoryServices != null) {
            services.add(memoryServices);
        }

        return services;
    }

    private AIServiceValue getHyperVMemoryService() {
        String info =  SystemPlugin.HYPERV_MEMORY;
        AIServiceValue svc = 
            createSystemService(SystemPlugin.HYPERV_MEMORY,
                                 getFullServiceName(info));
        svc.setMeasurementConfig(ConfigResponse.EMPTY_CONFIG);
        svc.setProductConfig(ConfigResponse.EMPTY_CONFIG);
        return svc;
    }
    
 

}