// Used by:
// Cards 2495, 2559, 2579, 3389 using item ad_gh_iceblaster
// Card ???? using item ad_dme2_freezeray

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.entity.character.Character;
	import game.creators.entity.EmitterCreator;
	import game.creators.entity.character.CharacterCreator;
	import game.data.TimedEvent;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Sword;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;

	/**
	 * Shoot freeze ray gun using line emitter and embeds NPC in ice
	 * 
	 * Required params:
	 * swfPath		Path to swf that is block of ice
	 * 
	 * Optional params:
	 * color		Color of ray beam (default is light blue)
	 */
	public class FreezeRay extends SpecialAbility
	{		
		override public function activate( node:SpecialAbilityNode ):void
		{
			var currentState:String = CharUtils.getStateType(entity)
			if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
			{
				// sword animation
				CharUtils.setAnim( super.entity, Sword );
				
				// setup listeners
				CharUtils.getTimeline(super.entity).handleLabel("fire", shoot);		
				CharUtils.getTimeline(super.entity).handleLabel("hold", freeze);
			}
		}	
		
		/**
		 * Shoot freeze ray 
		 */
		private function shoot():void
		{
			// if not active
			if ( !super.data.isActive )
			{
				// get character spatials
				var charspatial:Spatial = super.entity.get(Spatial);
				var handSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
				
				// get direction
				var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
				
				// get position for emitter
				var xPos:Number = charspatial.x - (handSpatial.x * charspatial.scale) + 30;
				var yPos:Number = charspatial.y + (handSpatial.y * charspatial.scale) - 6;
				
				// get ray direction
				var rayDirection:Number = 1;
				if (direction == CharUtils.DIRECTION_LEFT)
				{
					rayDirection = -1;
					xPos = charspatial.x + (handSpatial.x * charspatial.scale) - 30;
				}
				
				// set up emitter
				var emitter:Emitter2D = new Emitter2D;
				emitter.counter = new TimePeriod(40, 0.08);
				
				emitter.addInitializer( new ImageClass( Dot, [5, 0x33FFFF], true) );
				var rayVelocity:Number = 200 * rayDirection;
				emitter.addInitializer(new Velocity(new LineZone(new Point(rayVelocity, 0), new Point(rayVelocity, 0))));
				emitter.addInitializer( new Lifetime( 3, 3 ) );
				
				emitter.addAction(new Age());
				emitter.addAction(new Move());
				emitter.addAction( new Accelerate( rayDirection * 400, 0 ) );
				emitter.addAction( new ScaleImage( 0.35, 1 ) );
				
				var _emitter:Entity = EmitterCreator.create( group, super.entity.get(Display).container, emitter, xPos, yPos );
			}
		}
		
		/**
		 * Freeze NPCs in path of ray beam
		 */
		private function freeze():void
		{
			// if not active
			if ( !super.data.isActive )
			{
				var playerSpatial:Spatial = super.entity.get(Spatial);
				
				// get NPCs in scene
				var inSceneNpcs:Vector.<Entity> = (super.group.getGroupById('characterGroup') as CharacterGroup).getCharactersInView();
				if(inSceneNpcs)
				{
					// for each NPC
					for (var i:int = 0; i < inSceneNpcs.length; i++) 
					{
						var npc:Entity = inSceneNpcs[i];
						
						// exclude pop follower
						var npcID:Id = npc.get(Id);
						if ((npcID) && (npcID.id.indexOf("popFollower") == 0))
							continue;

						// skip mannequins
						if ((npc.has(Character)) && (npc.get(Character).variant == CharacterCreator.VARIANT_MANNEQUIN))
							continue;

						var npcSpatial:Spatial = npc.get(Spatial);
						
						// if horizontally close
						if(Math.abs(playerSpatial.y - npcSpatial.y) < 48)
						{
							// if NPC is in path
							if(((playerSpatial.scaleX > 0) && (playerSpatial.x > npcSpatial.x)) || ((playerSpatial.scaleX < 0) && (playerSpatial.x < npcSpatial.x)))
							{
								// remember entity
								_targetEntity = npc;
								
								// load block of ice
								super.loadAsset( _swfPath, placeBlock);
								
								// apply color glow to NPC
								var colorF:GlowFilter = new GlowFilter(_color, 1, 100, 100, 1, 1, true);
								npc.get(Display).displayObject.filters = [colorF];
								
								// add time to unfreeze
								SceneUtil.addTimedEvent( super.group, new TimedEvent( 2.7, 1, unFreeze ) );
								
								// make active
								super.setActive(true);
								return;
							}
						}
					}
				}
			}
		}
		
		/**
		 * Place block of ice over NPC 
		 * @param asset
		 */
		private function placeBlock( asset:DisplayObjectContainer):void
		{
			if (asset == null)
				return;
			
			// rememeber clip
			_clip = MovieClip(asset);
			
			// add clip to scene container
			var sceneContainer:DisplayObjectContainer = super.entity.get(Display).container;
			sceneContainer.addChild(_clip);
			
			// create entity for block
			_blockEntity = new Entity();
			_blockEntity.add(new Display(_clip, sceneContainer));

			// set block posiiton
			var npcSpatial:Spatial = _targetEntity.get( Spatial );
			var spatial:Spatial = new Spatial(npcSpatial.x, npcSpatial.y + 35);
			_blockEntity.add(spatial);
			super.group.addEntity(_blockEntity);
			
			// freeze npc (doesn't seem to work perfectly)
			CharUtils.freeze(_targetEntity, true);
			
			// convert block to timeline and add listener
			var vTimeline:Entity = TimelineUtils.convertClip(_clip, group);
			TimelineUtils.onLabel( vTimeline, Animation.LABEL_ENDING, removeBlock);
		}
		
		/**
		 * Unfreeze all NPCs 
		 */
		private function unFreeze():void
		{
			// for all NPCs
			var nodeList:NodeList = super.group.systemManager.getNodeList( NpcNode );
			for( var nodenpc : NpcNode = nodeList.head; nodenpc; nodenpc = nodenpc.next )
			{
				// remove filter and unfreeze
				nodenpc.entity.get(Display).displayObject.filters = [];
				CharUtils.freeze(nodenpc.entity, false);
			}
		}
		
		/**
		 * Remove block from scene container 
		 */
		private function removeBlock():void
		{
			super.setActive(false);
			super.group.removeEntity(_blockEntity);
			_blockEntity = null;
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			unFreeze();
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _color:uint = 0xABFAFC;
		
		private var _targetEntity:Entity;
		private var _blockEntity:Entity;
		private var _clip:MovieClip;
	}
}