// Status: retired
// Usage (1) ads
// Used by avatar item limited_carkey

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class CarRide extends SpecialAbility
	{
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!super.data.isActive)
			{
				super.setActive(true);				
				// lock input
				_inCar = false;
				 _stopCar = false;
				 _restartCar = false;
				_loadedNPC = false;
				 _driveOff = false;
				 settimer = true;
				 settimer2 = true;
				 settimer3 = true;
				 _passes = 0;
				SceneUtil.lockInput(super.group, true);
				
				if(super.data.params.byId( "xoffset" ) != null)
					_xOffset = super.data.params.byId("xoffset");
				
				// get swf path and load
				var swfPath:String = String( super.data.params.byId( "swfPath" ) );			
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
			NPCPlayer = charGroup.createNpcPlayer( onCharLoaded, null, new Point(xPos, yPos+40));
			NPCPlayer.get(Spatial).scaleX = super.entity.get(Spatial).scaleX;
			
			// remember car clip
			_clip = clip;
			
			// Create car entity and set the display and spatial
			_car = new Entity();
			_car.add(new Display(clip.content.car, super.entity.get(Display).container));
			super.group.addEntity(_car);
			
			
			_logo = new Entity();
			_logo.add(new Display(clip.content.logo, super.entity.get(Display).container));
			super.group.addEntity(_logo);
			
			_logo1 = new Entity();
			_logo1.add(new Display(clip.content.car.logos.logo1, super.entity.get(Display).container));
			super.group.addEntity(_logo1);

			_logo2 = new Entity();
			_logo2.add(new Display(clip.content.car.logos.logo2, super.entity.get(Display).container));
			super.group.addEntity(_logo2);
			
			_logo3 = new Entity();
			_logo3.add(new Display(clip.content.car.logos.logo3, super.entity.get(Display).container));
			super.group.addEntity(_logo3);
			
			_logo4 = new Entity();
			_logo4.add(new Display(clip.content.car.logos.logo4, super.entity.get(Display).container));
			super.group.addEntity(_logo4);
			
			var spatial:Spatial = new Spatial(super.shellApi.camera.viewport.x, charSpatial.y-20);

			_car.add(spatial);
			 
			var logospatial:Spatial = new Spatial(super.entity.get(Spatial).x,super.shellApi.camera.viewport.top + 200);
			_logo.add(logospatial);
			
			var logospatial1:Spatial = new Spatial(_car.get(Spatial).x,_car.get(Spatial).y);
			_logo1.add(logospatial1);
			var logospatial2:Spatial = new Spatial(_car.get(Spatial).x,_car.get(Spatial).y);
			_logo2.add(logospatial2);
			var logospatial3:Spatial = new Spatial(_car.get(Spatial).x,_car.get(Spatial).y);
			_logo3.add(logospatial3);
			var logospatial4:Spatial = new Spatial(_car.get(Spatial).x,_car.get(Spatial).y);
			_logo4.add(logospatial4);
			// this converts the content clip for AS3
			var vTimeline:Entity = TimelineUtils.convertClip(clip.content, super.group);
		}
		
		private function onCharLoaded( charEntity:Entity = null ):void
		{
			_loadedNPC = true;
		}
		
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			
			if(_car && _loadedNPC)
			{
				var charSpatial:Spatial = NPCPlayer.get(Spatial);
				var carSpatial:Spatial = _car.get(Spatial);
				var boundsX:Number = super.shellApi.camera.viewportWidth;			
				var relativeX:Number = super.shellApi.offsetX(carSpatial.x);
				var logospatial1:Spatial = _logo1.get(Spatial);
				var logospatial2:Spatial = _logo2.get(Spatial);
				var logospatial3:Spatial = _logo3.get(Spatial);
				var logospatial4:Spatial = _logo4.get(Spatial);
				
				if(_moving)
				{
					if(carSpatial.scaleX > 0)
					{
						logospatial1.x = carSpatial.x - 50; 
						logospatial2.x = carSpatial.x + 50; 
						logospatial2.y = carSpatial.y - 10; 
						logospatial3.x = carSpatial.x - 50; 
						logospatial3.y = carSpatial.y + 35; 
						logospatial4.x = carSpatial.x + 50; 
						logospatial4.y = carSpatial.y + 35; 
					}
					
					if(carSpatial.scaleX < 0)
					{
						logospatial2.x = carSpatial.x - 150; 
						logospatial1.x = carSpatial.x - 0; 
						logospatial2.y = carSpatial.y - 10; 
						logospatial4.x = carSpatial.x - 150; 
						logospatial3.y = carSpatial.y + 35; 
						logospatial3.x = carSpatial.x - 50; 
						logospatial4.y = carSpatial.y + 35; 
					}
				}
				if(!_inCar && _car.get(Spatial).x < charSpatial.x)
				{
					carSpatial.x += _speed;
				}
				else 
					_inCar = true;
				
				if(_inCar && !_restartCar)
				{
					charSpatial.x = carSpatial.x;
					charSpatial.y = carSpatial.y;
					if(charSpatial.scaleX >0)
						charSpatial.scaleX *= -1;
					
					if(settimer)
					{
					timer = new Timer(1000, 1);
					timer.addEventListener(TimerEvent.TIMER_COMPLETE, startCar);
					timer.start();
					settimer = false;
					_moving = false;
					}
				}
				
				if(_restartCar && !_stopCar)
				{
					if(charSpatial.scaleX < 0)
						charSpatial.x = carSpatial.x + 30 ;
						else
							charSpatial.x = carSpatial.x - 30;
						
					
					charSpatial.y = carSpatial.y;
					carSpatial.x += _speed;
					_moving = true;
					if(relativeX - _xOffset > boundsX && _addPass > 0|| relativeX + (_xOffset/2) < 0 && _addPass < 0)
					{
						_speed *= -1;
						charSpatial.scaleX *= -1;
						carSpatial.scaleX *= -1;
						_passes++;
						_addPass *= -1;
						
						
					}
					if(_passes == 4 && carSpatial.x >  node.entity.get(Spatial).x + (_xOffset/4) )
					{
						node.entity.get(Display).alpha = 1;
						NPCPlayer.get(Display).alpha = 0;
						
						if(settimer2)
						{
						timer2 = new Timer(1000, 1);
						timer2.addEventListener(TimerEvent.TIMER_COMPLETE, driveCarOff);
						timer2.start();
						settimer2 = false;
						_moving = false;
						}
						_stopCar = true;
					}
				}
				

				if(_driveOff)
				{
					carSpatial.x += _speed;
					_moving = true;
					if(settimer3)
					{
					timer3 = new Timer(1000, 1);
					timer3.addEventListener(TimerEvent.TIMER_COMPLETE, endPopup);
					timer3.start();
					settimer3 = false;
					}
				}
			}
		}
		
		private function endPopup(e:Event):void
		{
			endPopupAnim();
			timer3.removeEventListener(TimerEvent.TIMER_COMPLETE, endPopup);
		}
		
		private function driveCarOff(e:Event):void
		{
			_driveOff = true;
			timer2.removeEventListener(TimerEvent.TIMER_COMPLETE, driveCarOff);
		}
		
		private function startCar(e:Event):void
		{
			_restartCar = true;
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, startCar);
		}
		
		private function endPopupAnim():void
		{
			// remove clip

			super.group.removeEntity(_car);
			super.group.removeEntity(_logo);
			super.group.removeEntity(_logo1);
			super.group.removeEntity(_logo2);
			super.group.removeEntity(_logo3);
			super.group.removeEntity(_logo4);
			//remove NPC player
			super.group.removeEntity(NPCPlayer);
			// make player visible
			super.entity.get(Display).alpha = 1;
			// enable user input
			SceneUtil.lockInput(super.group, false);
			// make inactive
			super.setActive( false );
			super.removeSpecial(super.theNode);
		}
		
		private var NPCPlayer:Entity;
		private var _clip:MovieClip;
		private var _car:Entity;
		private var _logo:Entity;
		private var _logo1:Entity;
		private var _logo2:Entity;
		private var _logo3:Entity;
		private var _logo4:Entity;
		private var _speed:int = 20;
		private var _passes:Number = 0;
		private var _inCar:Boolean = false;
		private var _stopCar:Boolean = false;
		private var _restartCar:Boolean = false;
		private var _xOffset:Number = 0;
		private var _driveOff:Boolean = false;
		private var _loadedNPC:Boolean = false;
		private var timer3:Timer;
		private var timer2:Timer;
		private var timer:Timer;
		private var settimer3:Boolean;
		private var settimer2:Boolean;
		private var settimer:Boolean;
		private var _addPass:Number = 1;
		private var _moving:Boolean = true;

	}
}


