package com.poptropica.shells.mobile.steps
{
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;

	public class ResumeDeviceIdle extends ShellStep
	{
		public function ResumeDeviceIdle()
		{
			super();
		}
		
		override protected function build():void
		{
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
			super.built();
		}
	}
}