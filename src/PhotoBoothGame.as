package {

import com.poptropica.AppConfig;
import com.poptropica.DebugConfig;
import com.poptropica.PopAppBase;
import com.poptropica.shells.photoBooth.PhotoBoothShell;

import game.manifest.desktop.ClassManifestDesktop;

[SWF(frameRate='60', backgroundColor='#000000')]

/**
 * 
 * @author Rich Martin
 * 
 */	
public class PhotoBoothGame extends PopAppBase {

	
	public function PhotoBoothGame()
	{
		super();
		new ClassManifestDesktop();
		
		/*
		 * DEBUG FOR DEVELOPERS
		 * Developers can manually adjust configuration flags and modes within the DebugConfig.
		 * These settinsg will be overridden by Jenkins' build process.
		 * TODO :: Would like SVN to ignore DebugConfig commits
		 */
		DebugConfig.setFlags( DebugConfig.MODE_MOBILE );
		AppConfig.adsActive = false;
		
		/*
		 * JENKINS CONFIG
		 * Apply values set by Jenkins' build process before starting build steps/
		 * TODO :: This is still a little tricky in terms of allowing local debug settings
		 */
		preBuild();

		/*
		 * Create appropriate shell type, which constructs the application based on a sequence of BuildSteps
		 */
		var shell:Shell = new PhotoBoothShell();
		/*
		var shell:Shell;
		if( PlatformUtils.inBrowser || AppConfig.forceBrowser )
		{
			shell = new BrowserShell() as BrowserShell;
		}
		else if ( PlatformUtils.isMobileOS )
		{
			// check for Android or iOS
			if( PlatformUtils.isAndroid )
			{
				shell = new AndroidShell() as AndroidShell;
			}
			else
			{
				shell = new IosShell() as IosShell;
			}
		}
		else
		{
			shell = new DesktopShell() as DesktopShell;
		}
		*/
		
		/*
		 * JENKINS CONFIG
		 * Apply values set by Jenkins' build process after build steps have completed
		 */
		shell.complete.addOnce(postBuild);
		
		addChild(shell);
	}
}

}
