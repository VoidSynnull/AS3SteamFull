package game.scenes.con1.roofRace.NavigationSmart
{
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.util.MotionUtils;
	
	public class NavigationSmartSystem extends GameSystem
	{
		/*
		private var hitArea:BitmapData;
		private var hitDictionary:Dictionary;
		private var hitScale:Number;
		private var hitOffset:Point;
		private var hitWrapX:uint;
		
		private var canvas:Sprite = null;
		public static var _debug:Boolean = false;
		
		public function NavigationSmartSystem(collisionGroup:CollisionGroup, debug:Boolean = false)
		{
		hitArea = collisionGroup.hitBitmapData;
		hitDictionary = collisionGroup.allHitData;
		hitScale = collisionGroup.hitBitmapDataScale;
		hitOffset = new Point(collisionGroup.hitBitmapOffsetX, collisionGroup.hitBitmapOffsetY);
		
		canvas = new Sprite();
		var container:DisplayObjectContainer = PlatformerGameScene(collisionGroup.parent).hitContainer;
		container.addChild(canvas);
		canvas.graphics.lineStyle(2);
		
		_debug = debug;
		
		super(NavigationSmartNode, updateNode);
		}
		//*/
		//*
		public function NavigationSmartSystem()
		{
			super(NavigationSmartNode, updateNode);
		}
		//*/
		
		public function updateNode(node:NavigationSmartNode, time:Number):void
		{
			if(node.fsm.state)
			{
				var state:String = node.fsm.state.type;
				
				if(state == CharacterState.RUN || state == CharacterState.WALK)
				{
					//jump if there is a gap infront of you//not working at all
					//checkForGaps(node);
				}
				if(state == CharacterState.JUMP)
				{
					// if they jump after having just landed
					if(node.smart.state == CharacterState.LAND)
						jump(node);
				}
				if(node.target.targetReached)
					reachedTarget(node);
				
				node.smart.state = state;
			}
		}
		
		private function reachedTarget(node:NavigationSmartNode):void
		{
			node.smart.tries = 0;
		}
		
		private function jump(node:NavigationSmartNode):void
		{
			node.smart.tries++;
			if(node.smart.tries >= 3)//dont jump more than 3 times
			{
				findACloserPathPoint(node);// if you do give up and find a differnt point
				/*
				var pathPoint:Point = node.navigation.path[node.navigation.index];
				node.motion.x = pathPoint.x;
				node.motion.y = pathPoint.y;
				MotionUtils.zeroMotion(node.entity);
				*/
			}
		}
		
		private function findACloserPathPoint(node:NavigationSmartNode):void
		{
			node.smart.tries = 0;
			var distance:Number = 10000;
			var pos:Point = new Point(node.motion.x, node.motion.y);
			var target:Point;
			var pathNum:uint =0;
			if(node.navigation.path == null)
				return;
			for (var i:int = 0; i < node.navigation.path.length; i++)
			{
				var point:Point = node.navigation.path[i];
				var checkDistance:Number = Point.distance(point, pos);
				if(checkDistance < distance)
				{
					distance = checkDistance;
					target = point;
					pathNum = i;
				}
			}
			
			node.navigation.index = pathNum;
			node.target.targetX = target.x;
			node.target.targetY = target.y;
		}
		/* // this is not working at all
		private function checkForGaps(node:NavigationSmartNode):void
		{
		var feetY:Number = node.motion.y + node.edge.bottom;
		// if your target is below you or you are walking on the bottom of the scene
		if(node.target.targetY > feetY || node.bounds.bottom)
		return;
		
		var velocity:Point = new Point(node.motion.velocity.x, node.edge.bottom * 2);
		var hit:HitData = checkHit(node.motion.x, node.motion.y, velocity);
		if(hit == null)
		node.fsm.setState(CharacterState.JUMP);
		}
		
		private function checkHit(x:Number, y:Number, velocity:Point):HitData
		{
		//var hitColor:uint = hitArea.getPixel(x * hitScale + hitOffset.x, y * hitScale + hitOffset.y);
		//var hitData:HitData = hitDictionary[hitColor];
		var hitColor:uint = 0;
		var hitData:HitData = null;
		var dist:Number = Point.distance(new Point(), velocity);
		var targetX:Number = x;
		var targetY:Number = y;
		var negativeIndex:Number = 0;
		var ratioX:Number = velocity.x / dist;
		var ratioY:Number = velocity.y / dist;
		
		for(var i:uint = 0; i < dist; i++)
		{
		targetX += ratioX;
		targetY += ratioY;
		
		hitColor = hitArea.getPixel(targetX * hitScale + hitOffset.x, targetY * hitScale + hitOffset.y);
		hitData = hitDictionary[hitColor];
		
		if(hitData != null)
		{
		trace(hitColor);
		break;
		}
		}
		
		if(_debug)
		{
		canvas.graphics.clear();
		canvas.graphics.lineStyle(2,hitColor);
		canvas.graphics.moveTo(x,y);
		canvas.graphics.lineTo(x+velocity.x,y+velocity.y);
		}
		
		return hitData;
		*/
	}
}