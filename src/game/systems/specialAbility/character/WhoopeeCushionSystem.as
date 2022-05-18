package game.systems.specialAbility.character
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.CharacterWander;
	
	import game.components.Emitter;
	import game.components.specialAbility.WhoopeeComponent;
	import game.data.sound.SoundModifier;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.WhoopeeNode;
	import game.systems.GameSystem;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class WhoopeeCushionSystem extends GameSystem
	{
		public function WhoopeeCushionSystem()
		{
			super( WhoopeeNode, updateNode );
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			playerSpatial = group.shellApi.player.get( Spatial );
			_npcNodes = systemManager.getNodeList( NpcNode );
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( NpcNode );
		}
		
		private function updateNode( node:WhoopeeNode, time:Number ):void
		{
			var whoopeeCushion:WhoopeeComponent = node.whoopeeCushion;
			var spatial:Spatial = node.spatial;
			
			// check spinning entities
			for each (var char:Entity in whoopeeCushion.entities)
			{
				// if completed one spin, then reset
				if (Math.abs(char.get(Spatial).rotation) > 360)
				{
					makeStand(char, whoopeeCushion);
				}
			}
			
			// if normal or inflated and not triggered, then check NPCs near item
			if( ( spatial.scaleY >= 1 ) && ( !whoopeeCushion.isTriggered ) )
				checkPosition( node );
			
			// if not for slipping and not fully inflated, then inflate
			if((!whoopeeCushion.slip) && ( spatial.scaleY < 1.5 ))
				spatial.scaleY += .01;
			
			// release air if triggered and air effect
			if( ( whoopeeCushion.isTriggered ) && ( whoopeeCushion.doAirEffect ) )
				releaseAir( node );
		}
		
		private function checkPosition( node:WhoopeeNode ):void
		{
			var whoopeeCushion:WhoopeeComponent = node.whoopeeCushion;
			var spatial:Spatial = node.spatial;
			var motion:Motion = group.shellApi.player.get( Motion );
			var deltaX:Number = Math.abs( spatial.x - playerSpatial.x );
			var deltaY:Number = spatial.y - playerSpatial.y;
			var npc:NpcNode;
			var npcSpatial:Spatial;
						
			// if near player
			if( ( deltaX < 10 ) && ( deltaY < 55 ) && ( deltaY > 10 ) )
			{
				// if player walking
				if( Math.abs( motion.velocity.x ) > 0 )
					trigger( node, motion, group.shellApi.player );
			}
			else
			{
				// else check NPCs
				for ( npc = _npcNodes.head; npc; npc = npc.next )
				{
					npcSpatial = npc.spatial;
					deltaX = Math.abs( spatial.x - npcSpatial.x );
					deltaY = spatial.y - npcSpatial.y;
					
					// if near npc
					if( ( deltaX < 10 ) && ( deltaY < 55 ) && ( deltaY > 10 ) )
					{
						motion = npc.entity.get( Motion )
						// if npc has motion and walking
						if( ( motion ) && ( Math.abs( motion.velocity.x ) > 0 )	 )
							trigger( node, motion, npc.entity);
					}
				}
			}
		}
		
		private function trigger( node:WhoopeeNode, motion:Motion, npc:Entity ):void
		{
			var whoopeeCushion:WhoopeeComponent = node.whoopeeCushion;
			var number:int;
			var audio:Audio = node.audio;
			
			whoopeeCushion.timer = 30;
			whoopeeCushion.isTriggered = true;
						
			// play random sound
			if( whoopeeCushion.numberOfSounds != 0  && audio != null)
			{
				do
				{
					// get random number starting at 1 to number of sounds
					var vRandom:Number = Math.floor( whoopeeCushion.numberOfSounds * Math.random()) + 1;
					whoopeeCushion.isNewSound = false;
					if( vRandom != whoopeeCushion.lastSound )
					{
						whoopeeCushion.lastSound = vRandom;
						whoopeeCushion.isNewSound = true;
					}
				}
				while( !whoopeeCushion.isNewSound )
				
				var path:String = SoundManager.EFFECTS_PATH + whoopeeCushion.audioPrefix + vRandom + ".mp3";
				trace("play audio: " + path);
				audio.play( path, false, SoundModifier.POSITION );
			}
			
			// if doing air effect
			if ( whoopeeCushion.doAirEffect )
			{
				var entity:Entity = whoopeeCushion.emitterEntity;
				var emitter:Emitter2D = entity.get( Emitter ).emitter;
				emitter.counter = new Steady( 5 );
			}
			
			// if slip
			if (whoopeeCushion.slip)
			{
				// remember starting y position
				var y:Number = npc.get(Spatial).y;
				// set speed and spin
				if (motion.velocity.x > 0)
				{
					motion.velocity = new Point(whoopeeCushion.hSpeed, whoopeeCushion.vSpeed);
					motion.rotationVelocity = -whoopeeCushion.spin;
					motion.acceleration = new Point(whoopeeCushion.vAccel, 900);
				}
				else
				{
					motion.velocity = new Point(-whoopeeCushion.hSpeed, whoopeeCushion.vSpeed);
					motion.rotationVelocity = whoopeeCushion.spin;
					motion.acceleration = new Point(-whoopeeCushion.vAccel, 900);
				}
				// turn off wandering
				if (npc.has(CharacterWander))
					npc.get(CharacterWander).disabled = true;
					
				// add to list of entities
				whoopeeCushion.entities.push(npc);
				whoopeeCushion.startYs.push(y);
			}
		}
		
		private function makeStand(npc:Entity, whoopeeCushion:WhoopeeComponent):void
		{
			var index:int = whoopeeCushion.entities.indexOf(npc);
			if (index != -1)
			{
				// clear vertical velocity and spin
				var motion:Motion = npc.get(Motion);
				motion.velocity = new Point(motion.velocity.x, 0);
				motion.rotationVelocity = 0;
				motion.acceleration = new Point(motion.acceleration.x, 0);
				// reset rotation and y position
				var spatial:Spatial = npc.get(Spatial);
				spatial.rotation = 0;
				spatial.y = whoopeeCushion.startYs[index];
				// reset cushion so it will trigger again
				whoopeeCushion.isTriggered = false;
				// remove from list
				whoopeeCushion.entities.splice(index,1);
				whoopeeCushion.startYs.splice(index,1);
				// restore wandering
				if (npc.has(CharacterWander))
					npc.get(CharacterWander).disabled = false;
			}
		}
		
		private function releaseAir( node:WhoopeeNode ):void
		{
			var whoopeeCushion:WhoopeeComponent = node.whoopeeCushion;
			var spatial:Spatial = node.spatial; 
			var entity:Entity = whoopeeCushion.emitterEntity;
			
			var emitter:Emitter2D = entity.get( Emitter ).emitter;
			
			if( whoopeeCushion.timer > 0 )
			{
				var deltaScale:Number = ( spatial.scaleY - .8 ) / whoopeeCushion.timer;	
				
				spatial.scaleY -= deltaScale;
				whoopeeCushion.timer--;
			}
			else
			{ 
				whoopeeCushion.isTriggered = false;
				emitter.counter = new Steady( 0 );
			}
		}
		
		private function updateTimer( node:WhoopeeNode ):void
		{
			var whoopeeCushion:WhoopeeComponent = node.whoopeeCushion;
			if( whoopeeCushion.timer > 0 )
				whoopeeCushion.timer--;
			else
				whoopeeCushion.isTriggered = false;
		}
		
		private var playerSpatial:Spatial;
		private var _npcNodes:NodeList;
	}
}