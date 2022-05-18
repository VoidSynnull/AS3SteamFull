package com.poptropica {


public class MobileApp extends PopAppBase 
{
	public function MobileApp()
	{
		super();
		trace("MobileApp ctor: isProductionBuild is", isProductionBuild);
	}
	
	////////////////////////////// PRE-BUILD //////////////////////////////

	protected override function preBuild():void
	{
		trace("MobileApp::preBuild() invokes inherited method");
		super.preBuild();
		
		if( allowOverwrite )
		{
			writeIAPFlag();
		}
	}

	protected function writeIAPFlag():void
	{
		trace("MobileApp::writeIAPFlag() sets PlatformUtils.iapOn to", iapOn);
		AppConfig.iapOn = iapOn;
	}
	
	////////////////////////////// POST-BUILD //////////////////////////////
	
}

}