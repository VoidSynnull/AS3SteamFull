package
{
	import com.poptropica.AppConfig;
	import com.poptropica.DebugConfig;
	import com.poptropica.MobileApp;
	import com.poptropica.shells.mobile.ios.IosShell;
	
	import game.manifest.mobile.ClassManifestMobile;
	
	/**
	 * 
	 * @author Rich Martin
	 * 
	 */
	[SWF(frameRate='60', backgroundColor='#000000')]
	
	public class IosGame extends MobileApp
	{
	
		public function IosGame()
		{
			super();
			new ClassManifestMobile();
			
			/*
			 * DEBUG FOR DEVELOPERS
			 * Developers can manually adjust configuration flags and modes within the DebugConfig.
			 * These settings will be overridden by Jenkins' build process.
			 * TODO :: Would like SVN to ignore DebugConfig commits
			 */
			DebugConfig.setFlags( DebugConfig.MODE_MOBILE );
			trace(this," :: debug?", AppConfig.debug);
			
			/*
			 * JENKINS CONFIG
			 * Apply values set by Jenkins' build process, overrides AppConfig settings.
			 */
			preBuild();

			var shell:IosShell = new IosShell();
			
			/*
			 * JENKINS CONFIG
			 * Apply values set by Jenkins' build process after build steps have completed
			 */
			shell.complete.addOnce(postBuild);
			
			addChild(shell);
		}

	}

}
