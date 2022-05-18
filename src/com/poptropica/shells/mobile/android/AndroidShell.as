package com.poptropica.shells.mobile.android
{
	import com.poptropica.shellSteps.shared.SetupInjection;
	import com.poptropica.shells.mobile.MobileShell;
	import com.poptropica.shells.mobile.android.steps.AndroidStepSetPlatform;
	
	[SWF(frameRate='60', backgroundColor='#000000')]
	
	public class AndroidShell extends MobileShell
	{
		public function AndroidShell()
		{
			super();
		}
		
		override protected function construct():void
		{
			this.addStep(new SetupInjection());
			this.addStep(new AndroidStepSetPlatform());
			super.construct();
		}
	}
}