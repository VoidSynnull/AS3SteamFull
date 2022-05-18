package game.scenes.virusHunter.pdcLab.components
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	
	public class SensorTargetMC extends Component
	{
		public var mc:MovieClip; 
		public var tripFuncName:String;
		public var outFuncName:String;
		
		public function SensorTargetMC($mc:MovieClip, $tripFuncName:String = null, $outFuncName:String = null){
			mc = $mc;
			tripFuncName = $tripFuncName;
			outFuncName = $outFuncName;
		}
	}
}