package game.util
{
	import com.poptropica.AppConfig;
	import com.poptropica.platformSpecific.mobile.IDeviceCheck;
	
	import flash.display.Stage;
	import flash.display.StageQuality;
	
	import game.data.PlatformType;

	public class PerformanceUtils
	{
		public function PerformanceUtils()
		{
		}
		
		public static function determineQualityLevel():int
		{
			var platform:String;
			var level:int = QUALITY_HIGHEST;
			
			if(PlatformUtils.isMobileOS && deviceCheck != null)
			{
				level = deviceCheck.getDeviceLevel();
			}
	
			return(level);
		}
		
		public static function determineAndSetVectorQuality():void
		{
			var newQuality:String;
			
			if(qualityLevel < QUALITY_MEDIUM && AppConfig.platformType != PlatformType.TABLET && AppConfig.platformType != PlatformType.DESKTOP)
			{
				newQuality = StageQuality.LOW;
			}
			else if(qualityLevel < QUALITY_HIGH || PlatformUtils.isMobileOS)
			{
				newQuality = StageQuality.MEDIUM;
			}
			else
			{
				newQuality = StageQuality.HIGH;
			}
			
			if(stage.quality != newQuality)
			{
				stage.quality = newQuality;
			}
		}
		
		public static function setMaxStageQuality():void
		{
			var newQuality:String;
			
			if(PlatformUtils.isMobileOS)
			{
				newQuality = StageQuality.MEDIUM;
			}
			else
			{
				newQuality = StageQuality.HIGH;
			}
			
			if(stage.quality != newQuality)
			{
				stage.quality = newQuality;
			}
		}
		
		public static function determineAndSetDefaultBitmapQuality():void
		{			
			if(qualityLevel < QUALITY_MEDIUM)
			{
				defaultBitmapQuality = .5;
			}
			else if(qualityLevel < QUALITY_HIGH)
			{
				defaultBitmapQuality = .75;
			}
			else
			{
				defaultBitmapQuality = 1;
			}
		}
		
		public static const QUALITY_LOWEST:int = 0;
		public static const QUALITY_LOWER:int = 20;
		public static const QUALITY_LOW:int = 40;
		public static const QUALITY_MEDIUM:int = 50;
		public static const QUALITY_HIGH:int = 60;
		public static const QUALITY_HIGHER:int = 80;
		public static const QUALITY_HIGHEST:int = 100;
		
		public static var qualityLevel:int = 0;
		public static var defaultBitmapQuality:Number = 1;
		public static var stage:Stage;
		public static var deviceCheck:IDeviceCheck;
	}
}