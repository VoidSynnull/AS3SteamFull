package game.ar.ArPopup
{
	import ash.core.Component;
	

	
	import game.ar.as3.CameraUtils;
	import game.ar.as3.DrawingUtils;
	
	import org.osflash.signals.Signal;
	
	public class ArEffect extends Component
	{
		//public var arManager:BRFManager;
		public var cam:CameraUtils;
		public var draw:DrawingUtils;
		
		public var cameraReady:Boolean = false;
		
		public var cameraFound:Signal;
		
		public var baseNodes:Vector.<FacialLandMarks>;
		
		public var focusChanged:Signal;
		
		public function get faceInFocus():int{return _faceInFocus;}
		
		public function set faceInFocus(i:int):void
		{
			if(i != _faceInFocus)
			{
				_faceInFocus = i;
				focusChanged.dispatch(i);
			}
		}
		
		private var _faceInFocus:int = -1;
		
		//public var faces : Vector.<BRFFace>;
		
		public function ArEffect(numFacesToTrack:int = 2, landMarks:Vector.<int> = null)
		{
			cameraFound = new Signal(Boolean);
			baseNodes = new Vector.<FacialLandMarks>();
			for(var i:int = 0; i < numFacesToTrack; i ++)
			{
				baseNodes.push(new FacialLandMarks(landMarks));
			}
			focusChanged = new Signal(int);
		}
	}
}