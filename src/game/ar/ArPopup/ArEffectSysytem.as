package game.ar.ArPopup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	//import brfv4.BRFFace;
	//import brfv4.BRFManager;
	//import brfv4.BRFState;
	
	import engine.util.Command;
	
	import game.ar.as3.CameraUtils;
	import game.ar.as3.DrawingUtils;
	//import game.ar.utils.BRFv4PointUtils;
	import game.systems.GameSystem;
	import game.util.PlatformUtils;
	
	public class ArEffectSysytem extends GameSystem
	{
		private const APP_ID:String = "com.storyArc.poptropica";
		// key facial landmarks
		public static const LEFT_EAR:uint = 0;
		public static const RIGHT_EAR:uint = 16;
		public static const LEFT_BROW:uint = 19;
		public static const RIGHT_BROW:uint = 24;
		public static const NOSE_TOP:uint = 27;
		public static const NOSE_TIP:uint = 33;
		public static const LEFT_EYE:uint = 37;
		public static const RIGHT_EYE:uint = 44;
		public static const LEFT_CORNER:uint = 48;
		public static const RIGHT_CORNER:uint = 54;
		public static const UPPER_LIP:uint = 51;
		public static const LOWER_LIP:uint = 57;
		public static const UPPER_MOUTH:uint = 62;
		public static const LOWER_MOUTH:uint = 66;
		
		public static var DEBUG:Boolean = false;
		
		public static const DEFAULT:int = 0;
		public static const SMILE:String = "smile";
		public static const FROWN:String = "frown";
		public static const YAWN:String = "yawn";
		public static const CLICK:String = "click";
		// all the key land marks in logicl depth order
		public static function GetLandMarkOrder():Vector.<int>
		{
			var landMark:Vector.<int> = new Vector.<int>();
			
			landMark.push(LOWER_MOUTH, UPPER_MOUTH, LEFT_CORNER, RIGHT_CORNER, LOWER_LIP, UPPER_LIP,
				LEFT_EAR, RIGHT_EAR, LEFT_EYE, RIGHT_EYE, LEFT_BROW, RIGHT_BROW,NOSE_TOP, NOSE_TIP);
			
			return landMark;
		}
		
		//private var toDegree:Function = BRFv4PointUtils.toDegree;
		
		private var emoteListeners:NodeList;
		
		private var readyMethod:Function;
		private var deniedMethod:Function;
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			emoteListeners = systemManager.getNodeList(ArAssetNode);
		}
		
		public function ArEffectSysytem()
		{
			super(ArEffectNode, UpdateNode,OnNodeAdded,OnNodeRemoved);
		}
		
		private function OnNodeAdded(node:ArEffectNode):void
		{
			trace("ar node added");
			//ar set up
			//node.arEffect.arManager = new BRFManager();
			var rect:Rectangle = new Rectangle(0, 0, group.shellApi.viewportWidth, group.shellApi.viewportHeight);
		//	node.arEffect.arManager.init(rect, rect, APP_ID);
			//node.arEffect.arManager.setNumFacesToTrack(node.arEffect.baseNodes.length);
			
			var maxFaceSize : Number = rect.height;
			
			if(rect.width < rect.height) {
				maxFaceSize = rect.width;
			}
			
			//node.arEffect.arManager.setFaceDetectionParams(		maxFaceSize * 0.20, maxFaceSize * 1.00, 12, 8);
			//node.arEffect.arManager.setFaceTrackingStartParams(	maxFaceSize * 0.20, maxFaceSize * 1.00, 32, 35, 32);
			//node.arEffect.arManager.setFaceTrackingResetParams(	maxFaceSize * 0.15, maxFaceSize * 1.00, 40, 55, 32);
			
			//cam and render set up
			node.arEffect.cam = new CameraUtils();
			var sprite:Sprite = new Sprite();
			node.display.displayObject.addChild(sprite);
			node.arEffect.draw = new DrawingUtils(sprite);
			
			var order:Vector.<int> = GetLandMarkOrder();
			
			for(var i:int = 0; i < node.arEffect.baseNodes.length; i++)
			{
				sprite = new Sprite();
				node.display.displayObject.addChild(sprite);
				var landMarks:FacialLandMarks = node.arEffect.baseNodes[i];
				landMarks.container = sprite;
				// adding the sprites in a logical order based on facial depth
				for(var o:int = 0; o < order.length; o++)
				{
					var val:int = order[o];
					if(landMarks.facialLandMarks.hasOwnProperty(val))
					{
						var landMark:FacialLandMarkData = landMarks.facialLandMarks[val];
						sprite.addChild(landMark.sprite);
					}
				}
			}
			
			var mirror:Boolean = !PlatformUtils.isIOS;
			var rotation:Number = 0;
			readyMethod = Command.create(OnCameraReady, node);
			node.arEffect.cam.addEventListener("ready",readyMethod);
			deniedMethod = Command.create(OnCameraDenied, node);
			node.arEffect.cam.addEventListener("denied",deniedMethod);
			
			var cameraFound:Boolean = node.arEffect.cam.init(rect.width, rect.height, mirror, rotation);
			if(!cameraFound)
			{
				node.arEffect.cameraFound.dispatch(false);
			}
		}
		
		private function removeListeners(node:ArEffectNode):void
		{
			node.arEffect.cam.removeEventListener("ready",readyMethod);
			node.arEffect.cam.removeEventListener("denied",deniedMethod);
			readyMethod = null;
			deniedMethod = null;
		}
		
		private function OnCameraDenied(event:Event, node:ArEffectNode):void
		{
			node.arEffect.cameraFound.dispatch(false);
		}
		
		private function OnCameraReady(event:Event, node:ArEffectNode):void
		{
			removeListeners(node);
			//node.arEffect.faces = node.arEffect.arManager.getFaces();
			node.arEffect.cameraReady = true;
			var disp:DisplayObjectContainer = node.display.displayObject;
			disp.addChildAt(node.arEffect.cam.video,0);//making sure camera doesn't cover everything else
			node.arEffect.cameraFound.dispatch(true);
		}
		
		private function OnNodeRemoved(node:ArEffectNode):void
		{
			if(readyMethod != null)
			{
				removeListeners(node);
			}
			//node.arEffect.arManager = null;
			node.arEffect.cam = null;
			node.arEffect.draw = null;
		}
		
		private function UpdateNode(node:ArEffectNode, time:Number):void
		{
			if(!node.arEffect.cameraReady)
				return;
			
			node.arEffect.cam.update();
			//node.arEffect.arManager.update(node.arEffect.cam.cameraData);
			node.arEffect.draw.clear();
			
			var faceInFocus:int = -1;
			var faceSize:Number = 0;
			//var face : BRFFace;
			
			//for(var i : int = 0; i < node.arEffect.faces.length; i++) 
			//{
				//face = node.arEffect.faces[i];
				
				//if(face.scale > faceSize && face.state == brfv4.BRFState.FACE_TRACKING)
				//{
					//faceSize = face.scale;
					//faceInFocus = i;
				//}
				
				//var landMarks:FacialLandMarks = node.arEffect.baseNodes[i];
				// facial feature movement tracking
				//DetermindMovement(node, face, landMarks);
				
				// set up so we can capture 4 different emotes open mouth, smile, and frown, and default (0) which is essentially idle
				//DetermineEmotes(face);
			//}
			
			node.arEffect.faceInFocus = faceInFocus;
			
			if(node.arEffect.faceInFocus != -1 && DEBUG)
			{
				//face = node.arEffect.faces[node.arEffect.faceInFocus];
				
				//node.arEffect.draw.drawTriangles(	face.vertices, face.triangles, false, 1.0, 0x00a0ff, 0.4);
				//node.arEffect.draw.drawVertices(	face.vertices, 2.0, false, 0x00a0ff, 0.4);
			}
		}
		
		/*private function DetermineEmotes(face:BRFFace):void
		{
			if(	face.state == brfv4.BRFState.FACE_TRACKING_START ||
				face.state == brfv4.BRFState.FACE_TRACKING) 
			{
				var mouthOpen : Number = GetDelta(UPPER_MOUTH, LOWER_MOUTH, face.vertices);
				
				// using eye dist as constant
				var testDelta : Number = GetDelta(LEFT_EYE + 2, RIGHT_EYE -2, face.vertices);
				
				var yawnFactor : Number = mouthOpen / testDelta;
				
				if(yawnFactor > 0.6)
				{
					HandleEmote(face,YAWN);
				}
				else
				{
					DetermineSmiling(face);
				}
			}
		}
		
		private function DetermineSmiling(face:BRFFace):void
		{
			if(	face.state == brfv4.BRFState.FACE_TRACKING_START ||
				face.state == brfv4.BRFState.FACE_TRACKING) 
			{
				var leftFrownDelta:Number = GetDelta(LEFT_CORNER, LOWER_MOUTH, face.vertices, "y");
				var leftSmileDelta:Number = GetDelta(LEFT_CORNER, UPPER_MOUTH, face.vertices, "y");
				
				var rightFrownDelta:Number = GetDelta(RIGHT_CORNER, LOWER_MOUTH, face.vertices, "y");
				var rightSmileDelta:Number = GetDelta(RIGHT_CORNER, UPPER_MOUTH, face.vertices, "y");
				
				var frownDelta:Number = (leftFrownDelta + rightFrownDelta) / 2;
				
				var smileDelta:Number = (leftSmileDelta + rightSmileDelta) / 2;
				
				//trace("frowning?: " + frownDelta.toFixed(2) + " : Smiling?: " + smileDelta.toFixed(2));
				
				if(smileDelta > -2.0)
				{
					HandleEmote(face,SMILE);
				}
				else if(frownDelta < -5.5)
				{
					HandleEmote(face,FROWN);
				}
				else
				{
					HandleEmote(face,DEFAULT);
				}
			}
		}
		
		private function HandleEmote(face:BRFFace, emote:*):void
		{
			for( var assetNode : ArAssetNode = emoteListeners.head; assetNode; assetNode = assetNode.next )
			{
				if(assetNode.asset.face != face)
					continue;
				
				if(assetNode.asset.emoteStates.hasOwnProperty(emote))
				{
					if(emote == DEFAULT && assetNode.asset.lastEmote == CLICK)// don't override clicks with defaults
						continue;
					
					if(emote != assetNode.asset.lastEmote && assetNode.asset.lastEmote != null)
						assetNode.asset.emoteStates[assetNode.asset.lastEmote] = false;
					if(!assetNode.asset.emoteStates[emote])
					{
						trace(emote);
						assetNode.asset.emoteStates[emote] = true;
						assetNode.timeline.gotoAndPlay(emote);
						assetNode.asset.lastEmote = emote;
					}
				}
			}
		}
		
		private function DetermineBlinking(face:BRFFace):void
		{
			// doesn't work very well with glasses
			if(face.state == brfv4.BRFState.FACE_TRACKING) 
			{
				var deltaL:Number = GetDelta(LEFT_EYE, LEFT_EYE +4, face.vertices);
				
				// using eye dist as constant
				var testDelta:Number = GetDelta(LEFT_EYE + 2, RIGHT_EYE -2, face.vertices);
				
				var leftVal:Number = deltaL / testDelta;
				
				if(leftVal < 0.175)
				{
					//trace("left eye blinked");
				}
				
				var deltaR:Number = GetDelta(RIGHT_EYE, RIGHT_EYE + 2, face.vertices);
				
				var rightVal:Number = deltaR / testDelta;
				
				if(rightVal < 0.175)
				{
					//trace("right eye blinked");
				}
			}
		}
		
		private function GetDelta(node1:int, node2:int, v:Vector.<Number>, axis:String = null):Number
		{
			var p0:Point = new Point();
			var p1:Point = new Point();
			setPoint(v, node1, p0);
			setPoint(v, node2, p1);
			
			if(axis == "x")
				return p1.x -p0.x;
			else if(axis == "y")
				return p1.y-p0.y;
			
			return calcDistance(p0, p1);
		}
		*/
		//private var setPoint : Function		= BRFv4PointUtils.setPoint;
		//private var calcDistance : Function	= BRFv4PointUtils.calcDistance;
		/*
		private function DetermindMovement(node:ArEffectNode, face:BRFFace, landMarks:FacialLandMarks):void
		{
			// get image container for the face
			
			var baseNode : Sprite = landMarks.container;
			
			if(		face.state == brfv4.BRFState.FACE_TRACKING_START ||
				face.state == brfv4.BRFState.FACE_TRACKING) 
			{
				// Face Tracking results: 68 facial feature points.
				
				// loop though and adjust all the determined facial features for the face
				for each (var landMark:FacialLandMarkData in landMarks.facialLandMarks)
				{
					landMark.sprite.x			= face.points[landMark.node].x;
					landMark.sprite.y			= face.points[landMark.node].y;
					
					landMark.sprite.scaleX		= (face.scale / 480) * (1 - toDegree(Math.abs(face.rotationY)) / 110.0);
					landMark.sprite.scaleY		= (face.scale / 480) * (1 - toDegree(Math.abs(face.rotationX)) / 110.0);
					landMark.sprite.rotation	= toDegree(face.rotationZ);
				}
				baseNode.alpha		= 1.0;
				
			} else {
				
				baseNode.alpha		= 0.0;
			}
		}
		*/
	}
}