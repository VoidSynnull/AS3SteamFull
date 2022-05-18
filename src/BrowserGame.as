package {

import com.poptropica.DebugConfig;
import com.poptropica.PopAppBase;
import com.poptropica.shellLoader.ShellLoader;
import com.poptropica.shells.browser.BrowserShell;

import game.manifest.browser.ClassManifestBrowser;

[SWF(frameRate='60', backgroundColor='#000000')]

/**
 * 
 * @author Rich Martin
 * 
 */	
public class BrowserGame extends PopAppBase {

	
	public function BrowserGame()
	{
		super();
		new ClassManifestBrowser();
		
		/*
		 * DEBUG FOR DEVELOPERS
		 * Developers can manually adjust configuration flags and modes within the DebugConfig.
		 * These settings will be overridden by Jenkins' build process.
		 * TODO :: Would like SVN to ignore DebugConfig commits
		 */
		DebugConfig.setFlags( DebugConfig.MODE_BROWSER );
		
		/*
		 * JENKINS CONFIG
		 * Apply values set by Jenkins' build process before starting build steps
		 */
		preBuild();

		/*
		 * Create shell which constructs the application based on a sequence of BuildSteps
		 */
		var shell:BrowserShell = new BrowserShell();
		shell.params = ShellLoader.params;
		
		/*
		 * JENKINS CONFIG
		 * Apply values set by Jenkins' build process after build steps have completed
		 */
		shell.complete.addOnce(postBuild);
		
		addChildAt(shell, 0);
	}
}

}
