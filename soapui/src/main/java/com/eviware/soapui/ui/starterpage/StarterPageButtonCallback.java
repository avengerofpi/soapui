package com.eviware.soapui.ui.starterpage;

import com.eviware.soapui.analytics.Analytics;
import com.eviware.soapui.analytics.SoapUIActions;
import com.eviware.soapui.impl.WorkspaceImpl;
import com.eviware.soapui.impl.actions.NewRestProjectAction;
import com.eviware.soapui.impl.actions.NewWsdlProjectAction;
import com.eviware.soapui.impl.rest.actions.explorer.EndpointExplorerAction;
import com.eviware.soapui.model.workspace.Workspace;

import javax.swing.SwingUtilities;

/**
 * 
 * This class provides methods for handling particular JavaScript events on the SoapUI Starter Page.
 *
 */
public class StarterPageButtonCallback {

	/**
	 * Identifier for this event handler class.
	 */
    public static String CALLBACK = "buttonCallback";

    private WorkspaceImpl workspace;

    /**
     * Creates a new <code>StarterPageButtonCallback</code> instance for the given workspace.
     * 
     * @param workspace Object repsenting a SoapUI workspace. This should generally be the currently
     * loaded workspace being managed by the SoapUI GUI rather than an object you create and manipulate
     * independently.
     */
    public StarterPageButtonCallback(Workspace workspace) {
        this.workspace = (WorkspaceImpl) workspace;
    }

    /**
     * Handle the SoapUI Starter Page 'New SOAP Project' action.
     * Triggers an <code>Analytics.trackAction</code> event.
     */
    public void createSoapProject() {
        Analytics.trackAction(SoapUIActions.OS_START_PAGE_NEW_SOAP_PROJECT);
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                new NewWsdlProjectAction().perform(workspace, null);
            }
        });
    }

    /**
     * Handle the SoapUI Starter Page 'New REST Project' action.
     * Triggers an <code>Analytics.trackAction</code> event.
     */
    public void createRestProject() {
        Analytics.trackAction(SoapUIActions.OS_START_PAGE_NEW_REST_PROJECT);
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                new NewRestProjectAction().perform(workspace, null);
            }
        });
    }

    /**
     * Handle the SoapUI Starter Page 'Test a SOAP API' action.
     * Triggers an <code>Analytics.trackAction</code> event recording
     * <link>SoapUIActions.OS_START_PAGE_LAUNCH_EXPLORER</link> label.
     */
    public void launchEndpointExplorer() {
        Analytics.trackAction(SoapUIActions.OS_START_PAGE_LAUNCH_EXPLORER);
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                new EndpointExplorerAction().actionPerformed(null);
            }
        });
    }

    /**
     * 
     * Triggers an <code>Analytics.trackAction</code> event recording <code>location</code>
     * (unspecified meaning) and <code>SoapUIActions.OS_START_PAGE_TRY_SUI_PRO</code> label.
     * 
     * @param location Unknown purpose and expectations for this parameter.
     */
    public void sendTryProAnalytics(String location) {
        Analytics.trackAction(SoapUIActions.OS_START_PAGE_TRY_SUI_PRO, "Type", location);
    }
}
