package game.systems.hit
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.audio.HitAudio;
	import game.components.hit.BounceWire;
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.HitAudioData;
	import game.data.sound.SoundAction;
	import game.data.sound.SoundData;
	import game.nodes.entity.collider.BounceWireCollisionNode;
	import game.nodes.hit.BounceWireHitNode;
	import game.systems.GameSystem;
	import game.util.MotionUtils;
	
	public class BounceWireSystem extends GameSystem
	{
		public function BounceWireSystem()
		{
			super(BounceWireCollisionNode, updateNode, addNode);
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_hits = systemManager.getNodeList(BounceWireHitNode);
		}
		
		private function updateNode(collisionNode:BounceWireCollisionNode, time:Number):void
		{
			var hitNode:BounceWireHitNode;
			var colliderMotion:Motion = collisionNode.motion;
			var colliderDisplay:Display = collisionNode.display;
			
			if(!collisionNode.collider.colliding)
			{
				var colliderBottom:DisplayObject = DisplayObjectContainer(collisionNode.display.displayObject).getChildByName("colliderBottom");
				for(hitNode = _hits.head; hitNode; hitNode = hitNode.next)
				{
					if(colliderMotion.velocity.y > 0 && hitNode.display.displayObject.hitTestObject(colliderBottom))
					{
						collisionNode.currentHit.hit = hitNode.entity;
						playAudio(collisionNode.entity);
						collisionNode.collider.colliding = true;
						collisionNode.collider.collider = hitNode.entity;
						updateWire(collisionNode, hitNode.entity);
						break;
					}
				}
			}
			else
			{
				updateWire(collisionNode, collisionNode.collider.collider);
			}	
		}
		
		private function updateWire(collisionNode:BounceWireCollisionNode, hitEntity:Entity):void
		{			
			var colliderMotion:Motion = collisionNode.motion;
			var colliderSpatial:Spatial = collisionNode.spatial;
			var colliderEdge:Edge = collisionNode.edge;
			var colliderDisplay:Display = collisionNode.display;
			var hitSpatial:Spatial = hitEntity.get(Spatial);
			var hitDisplay:Display = hitEntity.get(Display);
			var hit:BounceWire = hitEntity.get(BounceWire);
			var hitChild:MovieClip = MovieClip(hitDisplay.displayObject.getChildByName(hit.hitChild));
			
			if(colliderDisplay.displayObject.hitTestObject(hitChild))
			{
				collisionNode.platformCollider.isHit = true;
				var delX:Number = -(hitSpatial.x - colliderSpatial.x);
				var delY:Number = -(hitSpatial.y - (colliderSpatial.y + colliderEdge.rectangle.bottom));
				var spread:Number = collisionNode.collider.spread;
				
				if(colliderMotion.acceleration == null) 
					colliderMotion.acceleration = new Point(0, 0);
				
				colliderMotion.acceleration.y = -delY * hit.tension * 100 - MotionUtils.GRAVITY;
				
				if(!isNaN(hit.dampening))
					colliderMotion.acceleration.y *= (1-hit.dampening);
				
				hitChild.graphics.clear();
				hitChild.graphics.lineStyle(hit.lineSize, hit.lineColor);
				hitChild.graphics.beginFill(hit.lineColor, 0);
				hitChild.graphics.moveTo(-hit.radius, 0);
				hitChild.graphics.lineTo((delX - spread - hit.radius)/2, (delY + 2) / 2);
				hitChild.graphics.curveTo(delX - spread, delY + 2, delX, delY + 2);
				hitChild.graphics.curveTo(delX + spread, delY + 2, (delX + spread + hit.radius)/2, (delY + 2)/2);
				hitChild.graphics.lineTo(hit.radius, 0);
				hitChild.graphics.lineStyle(hit.lineSize, hit.lineColor, 0);
				hitChild.graphics.endFill();
				
				for(var i:uint = 0; i < hitDisplay.displayObject.numChildren; i++)
				{
					var currClip:DisplayObject = hitDisplay.displayObject.getChildAt(i);
					if(currClip is MovieClip && currClip != hitChild)
					{
						if(currClip.x < delX)
						{
							currClip.y = delY * (currClip.x + hit.radius) / (delX + hit.radius);
							currClip.rotation = Math.atan(delY / (delX + hit.radius)) * 180/Math.PI;
						}
						else
						{
							currClip.y = delY * (currClip.x - hit.radius) / (delX - hit.radius);
							currClip.rotation = Math.atan(delY / (delX - hit.radius)) * 180/Math.PI;
						}	
					}
				}
			}
			else
			{
				// reset the line to be back to a straight line and in its starting position
				hitChild.graphics.clear();
				hitChild.graphics.lineStyle(hit.lineSize, hit.lineColor);
				hitChild.graphics.moveTo(-hit.radius, 0);
				hitChild.graphics.lineTo(hit.radius, 0);
				
				// Reset the children so they are back where they started
				for(var j:uint = 0; j < hitDisplay.displayObject.numChildren; j++)
				{
					var clip:DisplayObject = hitDisplay.displayObject.getChildAt(j);
					if(clip is MovieClip && clip != hitChild)
					{
						clip.y = 0;
						clip.rotation = 0;
					}
				}
				
				collisionNode.currentHit.hit = hitEntity;
				playImpact(collisionNode.entity);
				collisionNode.platformCollider.isHit = false;
				collisionNode.collider.colliding = false;
				collisionNode.collider.collider = null;
			}
		}
		
		private function playAudio(entity:Entity):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			
			if(hitAudio != null)
			{
				hitAudio.active = true;
				hitAudio.action = SoundAction.WIRE_BOUNCE;
			}
		}
		
		private function playImpact(entity:Entity):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			if( hitAudio == null || hitAudio.hitEntity == null)
				return;
			var audioData:HitAudioData = hitAudio.hitEntity.get(HitAudioData);
			
			if(audioData != null)
			{
				var soundData:SoundData = audioData.currentActions[SoundAction.IMPACT];
				var audio:Audio = entity.get(Audio);
				if(audio != null)
				{
					audio.playFromSoundData(soundData);
				}
			}
		}
		
		private function addNode(node:BounceWireCollisionNode):void
		{
			var prevX:Number = node.spatial.scaleX;
			var prevY:Number = node.spatial.scaleY;
			
			var colliderBottom:Shape = new Shape();
			colliderBottom.name = "colliderBottom";
			node.spatial.scaleX = node.spatial.scaleY = 1;
			colliderBottom.graphics.beginFill(0xCCCCCC, 0);
			colliderBottom.graphics.drawRect(0, 0, node.spatial.width/2, 20);
			colliderBottom.graphics.endFill();
			colliderBottom.x = node.edge.rectangle.left;
			colliderBottom.y = node.edge.rectangle.bottom;
			node.spatial.scaleX = prevX;
			node.spatial.scaleY = prevY;
			node.display.displayObject.addChild(colliderBottom);
			
			for(var hitNode:BounceWireHitNode = _hits.head; hitNode; hitNode = hitNode.next)
			{
				var child:MovieClip = MovieClip(hitNode.display.displayObject.getChildByName(hitNode.hit.hitChild));
				// create the lines starting position
				child.graphics.clear();
				child.graphics.lineStyle(hitNode.hit.lineSize, hitNode.hit.lineColor);
				child.graphics.moveTo(-hitNode.hit.radius, 0);
				child.graphics.lineTo(hitNode.hit.radius, 0);
			}
		}
		
		[Inject]
		public var _shellApi:ShellApi;
		private var _hits:NodeList;
	}
}