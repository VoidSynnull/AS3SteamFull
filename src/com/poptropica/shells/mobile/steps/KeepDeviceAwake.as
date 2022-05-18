package com.poptropica.shells.mobile.steps
{
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;

	public class KeepDeviceAwake extends ShellStep
	{
		public function KeepDeviceAwake()
		{
			super();
		}
		
		override protected function build():void
		{
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			super.built();
		}
	}
}