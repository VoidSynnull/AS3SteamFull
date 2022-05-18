package game.ui.photo
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;

	public class CharacterPoseData
	{
		public var url:String;
		public var limbsDrawnOn:Boolean;
		public var lookTarget:DisplayObject;
		public var container:DisplayObjectContainer;
		public var mouthState:String;
		public var eyeState:String;
		private var _partData:Dictionary;
		
		public static const DEBUG:Boolean = false;
		
		public const MOUTH:String 					= "mouth_";
		public const EYES:String 					= "eyes_";
		public const MANUALLY_DRAWN_LIMBS:String 	= "mlimb_";
		public const LOOK_POINT:String				= "lookPoint";
		
		public const PART_ORDER: Vector.<String> = new <String> ["pack","hair","arm2","hand2","leg2","foot2","leg1","foot1","arm1","hand1","item","body","neck","head"];
		
		public function CharacterPoseData(display:DisplayObjectContainer, limbsDrawnOn:Boolean = true)
		{
			this.limbsDrawnOn = limbsDrawnOn;
			this.container = display;
			
			if(display.hasOwnProperty(LOOK_POINT))
			{
				lookTarget = display[LOOK_POINT];
				lookTarget.visible = false;
			}
			
			setUpPartData(display);
		}
		
		private function setUpPartData( display:DisplayObjectContainer):void
		{
			_partData = new Dictionary();
			
			// id like a way to set up mouth and eyes via this pose
			// so there can as few steps as possible in setting up a photo
			
			for(var i:int = 0; i < PART_ORDER.length; i++)
			{
				var partID:String = PART_ORDER[i];
				var partName:String = partID;
				
				var limb:Boolean = false;
				if(partID.indexOf("arm") == 0 || partID.indexOf("leg") == 0)
				{
					if(display.hasOwnProperty(MANUALLY_DRAWN_LIMBS + partID))
						partName = MANUALLY_DRAWN_LIMBS + partID;
					limb = true;
				}
				
				var clip:MovieClip = display[partName];
				
				setPart(partID, clip, limb);
				
				if(partID == "head")
				{
					for(var num:int = 0; num < clip.numChildren; num++)
					{
						var child:DisplayObject = clip.getChildAt(num);
						if(child is MovieClip)
						{
							if(child.name.indexOf(MOUTH) == 0)
							{
								if(child.name.length > MOUTH.length)
									mouthState = child.name.substr(MOUTH.length);
							}
							else if(child.name.indexOf(EYES) == 0)
							{
								if(child.name.length > EYES.length)
									eyeState = child.name.substr(EYES.length);
							}
						}
					}
				}
				
				if(!DEBUG)
				{
					if(!limb)
						display.removeChild(clip);
				}
			}
		}
		
		public function setPart(partId:String, display:DisplayObjectContainer, limb:Boolean):void
		{
			_partData[partId] = new PartPoseData(display, limb);
		}
		
		public function getPart(partId:String):PartPoseData
		{
			return _partData[partId] as PartPoseData;
		}
		
		public function get partData():Dictionary{return _partData;}
	}
}