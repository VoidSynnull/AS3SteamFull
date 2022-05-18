package com.poptropica.shellSteps.shared
{
	import com.poptropica.AppConfig;
	import com.poptropica.platformSpecific.mobile.IDeviceCheck;
	
	import game.util.PerformanceUtils;

	public class DetermineQualityLevel extends ShellStep
	{
		public function DetermineQualityLevel()
		{
			super();
			stepDescription = "Setting graphics quality";
		}
		
		
		override protected function build():void
		{
			// set the device specific check prior to calling PerformanceUtils.determineQualityLevel()
			// this allows for device specific quality checking
			if( super.shellApi.platform != null )
			{
				PerformanceUtils.deviceCheck = super.shellApi.platform.getInstance(IDeviceCheck) as IDeviceCheck;
			}
			
			// determine quality level, use preference level if available otherwise determine by device
			var qualityOverride:Number = Number(super.shellApi.profileManager.active.qualityOverride);
			if(!isNaN(qualityOverride) && qualityOverride > -1 )
			{
				PerformanceUtils.qualityLevel = Math.max(AppConfig.minimumQuality, qualityOverride);
			}
			else
			{
				PerformanceUtils.qualityLevel = Math.max(AppConfig.minimumQuality, PerformanceUtils.determineQualityLevel());
			}
			
			PerformanceUtils.determineAndSetVectorQuality();
			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			
			super.built();
		}
	}
}