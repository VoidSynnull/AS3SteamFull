// Status: retired
// Usage (1) ads
// Used by card 2537

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;

	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class DragonRide extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				super.setActive(true);
				initStep = true;
				
				// lock input
				SceneUtil.lockInput(super.group, true);
			
				// get swf path and load
				var swfPath:String = "limited/HowTrainDragon2May2014MVU/DragonRide.swf";
				super.loadAsset(swfPath, loadComplete);
			}
		}
		
		private function loadComplete(clip:MovieClip):void
		{
			var charSpatial:Spatial = super.entity.get(Spatial);
			var xPos:Number = charSpatial.x;
			var yPos:Number = charSpatial.y;
			
			// hide player
			super.entity.get(Display).alpha = 0;
			
			// create copy of player
			var charGroup:CharacterGroup = scene.getGroupById("characterGroup") as CharacterGroup;
			NPCPlayer = charGroup.createNpcPlayer(null, null, new Point(xPos, yPos+40));
			NPCPlayer.get(Spatial).scaleX = super.entity.get(Spatial).scaleX;
			
			// remember dragon clip
			_clip = clip;
			
			// Create dragon entity and set the display and spatial
			_dragon = new Entity();
			_dragon.add(new Display(clip, super.entity.get(Display).container));
			super.group.addEntity(_dragon);
			
			var handSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			baseX = charSpatial.x - (handSpatial.x * charSpatial.scale) + 24;
			baseY = charSpatial.y + (handSpatial.y * charSpatial.scale) - 12;
			
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				baseX = charSpatial.x + (handSpatial.x * charSpatial.scale) - 24;
			}
			
			var spatial:Spatial = new Spatial(baseX - offset, baseY - offset);
			_dragon.add(spatial);
			
			// this converts the content clip for AS3
			var vTimeline:Entity = TimelineUtils.convertClip(clip.content, super.group);
		}	
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if (_dragon)
			{
				switch ( currentFlightStep )
				{
					case 1: // fly in
						if (initStep)
						{
							initStep = false;
							startPointX = baseX - offset;
							startPointY = baseY - offset;
							endPointX = baseX;
							endPointY = baseY;
							animationStep = 0;
						}
						else
						{
							flyDragonEase();
						}
						break;
					case 2: // hop on
						currentFlightStep++;
						attached = true;
						initStep = true;
						break;
					case 3: // fly up
						if (initStep)
						{
							initStep = false;
							startPointX = baseX;
							startPointY = baseY;
							endPointX = baseX + offset;
							endPointY = baseY - offset;
							NPCPlayer.get(Spatial).scaleX = 0.36;
							animationStep = 0;
						}
						else
						{
							flyDragonEase();
						}
						break;
					case 4: // pause
						if (initStep)
						{
							initStep = false;
							pauseCounter = 10;
						}
						else
						{
							pauseFlight();
						}
						break;
					case 5: // right to left
						if (initStep)
						{
							initStep = false;
							startPointX = baseX + offset;
							startPointY = baseY - (Math.random() * 300);
							endPointX = baseX - offset;
							endPointY = baseY - (Math.random() * 300);
							_dragon.get(Spatial).scaleX = -1;
							NPCPlayer.get(Spatial).scaleX = -0.36;
							animationStep = 0;
						}
						else
						{
							flyDragonLinear();
						}
						break;
					case 6: // left to right
						if (initStep)
						{
							initStep = false;
							startPointX = baseX - offset;
							startPointY = baseY - (Math.random() * 300);
							endPointX = baseX + offset;
							endPointY = baseY - (Math.random() * 300);
							_dragon.get(Spatial).scaleX = 1;
							NPCPlayer.get(Spatial).scaleX = 0.36;
							animationStep = 0;
						}
						else
						{
							flyDragonLinear();
						}
						break;
					case 7: // soar up
						if (initStep)
						{
							initStep = false;
							startPointX = baseX + 160 * (0.5 - Math.random());
							startPointY = baseY + offset;
							endPointX = baseX + 160 * (0.5 - Math.random());
							endPointY = baseY - offset;
							_dragon.get(Spatial).rotation = 90;
							_dragon.get(Spatial).scaleX = -1;
							NPCPlayer.get(Spatial).rotation = 90;
							NPCPlayer.get(Spatial).scaleX = -0.36;
							animationStep = 0;
						}
						else
						{
							flyDragonLinear();
						}
						break;
					case 8: // soar down
						if (initStep)
						{
							initStep = false;
							startPointX = baseX + 160 * (0.5 - Math.random());
							startPointY = baseY - offset;
							endPointX = baseX + 160 * (0.5 - Math.random());
							endPointY = baseY + offset;
							_dragon.get(Spatial).rotation = 90;
							_dragon.get(Spatial).scaleX = 1;
							NPCPlayer.get(Spatial).rotation = 90;
							NPCPlayer.get(Spatial).scaleX = 0.36;
							animationStep = 0;
						}
						else
						{
							flyDragonLinear();
						}
						break;
					case 9: // pause
						if (initStep)
						{
							initStep = false;
							pauseCounter = 10;
						}
						else
						{
							pauseFlight();
						}
						break;
					case 10: // descend from upper right
						if (initStep)
						{
							initStep = false;
							startPointX = baseX + offset;
							startPointY = baseY - offset;
							endPointX = baseX;
							endPointY = baseY;
							_dragon.get(Spatial).rotation = 0;
							_dragon.get(Spatial).scaleX = -1;
							NPCPlayer.get(Spatial).rotation = 0;
							NPCPlayer.get(Spatial).scaleX = -0.36;
							animationStep = 0;
						}
						else
						{
							flyDragonEase();
						}
						break;
					case 11: // hop off
						currentFlightStep++;
						initStep = true;
						attached = false;
						NPCPlayer.get(Spatial).scaleX = node.entity.get(Spatial).scaleX;
						break;
					case 12: // fly away to upper left
						if (initStep)
						{
							initStep = false;
							startPointX = baseX;
							startPointY = baseY;
							endPointX = baseX - offset;
							endPointY = baseY - offset;
							animationStep = 0;
						}
						else
						{
							flyDragonEase();
						}
						break;
					case 13:
						endPopupAnim();
						break;
				}
			}
		}
		
		private function alignDragon():void
		{
			_dragon.get(Spatial).scaleX *= -1;
			_dragon.get(Spatial).rotation = (Math.atan2(endPointY - startPointY, endPointX - startPointX)) * (180 / Math.PI);
			if ( endPointX > startPointX)
				_dragon.get(Spatial).rotation += 180;
		}

		private function flyDragonLinear():void
		{
			_dragon.get(Spatial).x = startPointX + ((endPointX - startPointX) * (animationStep / linearAnimationDuration));
			_dragon.get(Spatial).y = startPointY + ((endPointY - startPointY) * (animationStep / linearAnimationDuration));
			if (attached)
			{
				NPCPlayer.get(Spatial).x = _dragon.get(Spatial).x;
				NPCPlayer.get(Spatial).y = _dragon.get(Spatial).y;
			}
			
			if ( animationStep == linearAnimationDuration )
			{
				currentFlightStep++;
				initStep = true;
			}
			else
			{
				animationStep++;
			}
		}
		
		private function flyDragonEase():void
		{
			_dragon.get(Spatial).x = startPointX + ((endPointX - startPointX) * Math.sin((animationStep / easeAnimationDuration) * (Math.PI / 2)));
			_dragon.get(Spatial).y = startPointY + ((endPointY - startPointY) * Math.sin((animationStep / easeAnimationDuration) * (Math.PI / 2)));
			if (attached)
			{
				NPCPlayer.get(Spatial).x = _dragon.get(Spatial).x;
				NPCPlayer.get(Spatial).y = _dragon.get(Spatial).y;
			}
			
			if ( animationStep == easeAnimationDuration )
			{
				currentFlightStep++;
				initStep = true;
			}
			else
			{
				animationStep++;
			}
		}
		
		private function pauseFlight():void
		{
			pauseCounter--;
			if ( pauseCounter <= 0 )
			{
				currentFlightStep++;
				initStep = true;
			}
		}
		
		private function endPopupAnim():void
		{
			// remove clip
			super.group.removeEntity(_dragon);
			//remove NPC player
			super.group.removeEntity(NPCPlayer);
			// make player visible
			super.entity.get(Display).alpha = 1;
			// enable user input
			SceneUtil.lockInput(super.group, false);
			// make inactive
			super.setActive( false );
		}
		
		private var NPCPlayer:Entity;
		private var _clip:MovieClip;
		private var _dragon:Entity;
		private var _speed:int = 30;
		private var currentFlightStep:int = 1;
		private var animationStep:int = 0;
		private var initStep:Boolean = true;
		private var pauseCounter:int = 0;
		private var startPointX:Number;
		private var startPointY:Number;
		private var endPointX:Number;
		private var endPointY:Number;
		private var baseX:Number;
		private var baseY:Number;
		private var attached:Boolean = false;
		private const easeAnimationDuration:int = 75;
		private const linearAnimationDuration:int = 40;
		private const offset:int = 800;
	}
}


