package game.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.display.StageQuality;
	import flash.events.Event;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Id;
	import engine.managers.SoundManager;
	
	import game.components.entity.Sleep;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	public class PerformanceMonitorSystem extends System
	{
		private var unmuteWhenActive:Boolean = false;
		
		public function PerformanceMonitorSystem(container:DisplayObjectContainer)
		{
			_container = container;
			_container.addEventListener(Event.ACTIVATE, handleActivate);
			_container.addEventListener(Event.DEACTIVATE, handleDeactivate);
			//_container.addEventListener(Event.MOUSE_LEAVE, handleMouseLeave);
		}

		override public function update( time : Number ) : void
		{			
			if(_applicationActive)
			{
				_totalFrameChecks++;
				_totalFrameTime += time;
			}
			
			if(this.showEntityCount)
			{
				if(_lastEntityTotal != _systemManager.entities.length)
				{
					_lastEntityTotal = _systemManager.entities.length;
					
					var totalSleeping:int = 0;
					var totalAwake:int = 0;
					var entity:Entity;
					var sleeping:Array = new Array();
					var awake:Array = new Array();
					var canSleep:Array = new Array();
					
					for(var n:uint = 0; n < _systemManager.entities.length; n++)
					{
						entity = _systemManager.entities[n];
						
						if(EntityUtils.sleeping(entity))
						{
							totalSleeping++;
					
							if(entity.get(Id))
							{
								sleeping.push(entity.get(Id).id);
							}
							else
							{
								sleeping.push(entity.name);
							}
						}
						else
						{
							totalAwake++;
	
							if(entity.get(Id))
							{
								awake.push(entity.get(Id).id);
							}
							else
							{
								awake.push(entity.name);
							}
						}
						
						if(entity.get(Sleep))
						{
							if(entity.get(Id))
							{
								canSleep.push(entity.get(Id).id);
							}
							else
							{
								canSleep.push(entity.name);
							}
						}
						
					}
					
					super.group.shellApi.log("total entities : " + _systemManager.entities.length + 
										     "\ntotal sleeping : " + totalSleeping + 
											 "\ntotal awake : " + totalAwake + 
											 "\n\n*** entities sleeping ***\n" + sleeping + 
											 "\n\n*** entities awake ***\n" + awake +
											 "\n\n*** entities with Sleep component ***\n" + canSleep);
				}
			}
			
		}
		
		public function handleActivate(event:Event = null):void
		{
			trace("PerformanceMonitorSystem :: activate");
			_applicationActive = true;
			
			if(PlatformUtils.isMobileOS)
			{
				_container.stage.frameRate = 60;
				_container.stage.quality = StageQuality.BEST;
				
				if(this.unmuteWhenActive)
				{
					this.unmuteWhenActive = false;
					this.soundManager.muteMixer(false);
				}
			}
		}
		
		private function handleDeactivate(event:Event):void
		{
			trace("PerformanceMonitorSystem :: deactivate");
			_applicationActive = false;
			
			if(PlatformUtils.isMobileOS)
			{
				_container.stage.quality = StageQuality.LOW;
				_container.stage.frameRate = 1;
				
				if(this.soundManager.mixerVolume != 0)
				{
					this.unmuteWhenActive = true;
					this.soundManager.muteMixer(true);
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_systemManager = systemManager;
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			_container.removeEventListener(Event.ACTIVATE, handleActivate);
			_container.removeEventListener(Event.DEACTIVATE, handleDeactivate);
			
			super.removeFromEngine(systemManager);
		}
		
		public function get averageFrameRate():Number 
		{ 
			if(_totalFrameChecks != 0)
			{
				return(1 / (_totalFrameTime / _totalFrameChecks));
			}
			else
			{
				return(0);
			}
		}
		private var _totalFrameChecks:int = 0;
		private var _totalFrameTime:Number = 0;
		private var _applicationActive:Boolean = true;
		private var _container:DisplayObjectContainer;
		private var _systemManager:Engine;
		
		public var showEntityCount:Boolean = false;
		public var showEntityDetails:Boolean = false;
		public var _lastEntityTotal:int = 0;
		[Inject]
		public var soundManager:SoundManager;
	}
}