package com.poptropica.shells.mobile.android
{
import com.poptropica.shellSteps.shared.SetupInjection;
import com.poptropica.shells.mobile.MobileShell;
import com.poptropica.shells.mobile.android.steps.AmazonAndroidShellSetPlatformStep;
	
	
	[SWF(frameRate='60', backgroundColor='#000000')]
	
	public class AmazonAndroidShell extends MobileShell
	{
		public function AmazonAndroidShell()
		{
			super();
		}
		
		override protected function construct():void
		{
			this.addStep(new SetupInjection());
			addStep(new AmazonAndroidShellSetPlatformStep());
			super.construct();
		}
		
	}
}