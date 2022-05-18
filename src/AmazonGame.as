package
{
	import com.poptropica.DebugConfig;
	import com.poptropica.MobileApp;
	import com.poptropica.shells.mobile.android.AmazonAndroidShell;
	
	import game.manifest.mobile.ClassManifestMobile;
	
	/**
	 * 
	 * @author Rich Martin
	 * 
	 */
	[SWF(frameRate='60', backgroundColor='#000000')]
	
	public class AmazonGame extends MobileApp
	{
		
		public function AmazonGame()
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
			
			/*
			 * JENKINS CONFIG
			 * Apply values set by Jenkins' build process, overrides AppConfig settings.
			 */
			preBuild();
			
			var shell:AmazonAndroidShell = new AmazonAndroidShell();
			
			/*
			 * JENKINS CONFIG
			 * Apply values set by Jenkins' build process after build steps have completed
			 */
			shell.complete.addOnce(postBuild);
			
			addChild(shell);
		}

	}

}
