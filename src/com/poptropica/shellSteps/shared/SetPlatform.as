package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	import com.poptropica.platformSpecific.Platform;

	/**
	 * Build step that determines the platform type.
	 * Should be first step in build sequence and overridden for each type of platform build.
	 * @author umckiba
	 */
	public class SetPlatform extends ShellStep
	{
		public function SetPlatform()
		{
			super();
		}
		
		override protected function build():void
		{
			AppConfig.mobile = false;
			this.shellApi.platform = new Platform();	// Goes to Browser by default, though we may want to change this. - bard
			
			built();
		}
	}
}