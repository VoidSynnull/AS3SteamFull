package com.poptropica.shells.mobile.ios
{
	import com.poptropica.shellSteps.shared.SetupInjection;
	import com.poptropica.shells.mobile.MobileShell;
	import com.poptropica.shells.mobile.ios.steps.IosStepSetPlatform;
	
	[SWF(frameRate='60', backgroundColor='#000000', wmode="gpu")]
	
	public class IosShell extends MobileShell
	{
		public function IosShell()
		{
			super();
		}
		
		override protected function construct():void
		{
			this.addStep(new SetupInjection());
			this.addStep(new IosStepSetPlatform());
			super.construct();
		}
	}
}