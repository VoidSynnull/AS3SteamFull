package game.scenes.arab3
{
	import ash.core.Entity;
	
	import engine.components.SpatialAddition;
	
	import game.components.entity.character.Character;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab3.shared.SmokePuffGroup;
	import game.systems.motion.WaveMotionSystem;
	
	public class Arab3Scene extends PlatformerGameScene
	{
		protected var _events:Arab3Events;
		protected var _audioGroup:AudioGroup;
		protected var _smokePuffGroup:SmokePuffGroup;
		
		protected var _numSpellTargets:Number 		= 2;   	// ONE OF THESE WILL BE INFRONT OF THE GENIE'S HANDS
		protected var _numThiefSpellTargets:Number 	= 0;
//		protected var _hasGenie:Boolean 	  	= true;
		protected var _hasThiefGenie:Boolean 	= false;
		
		public function Arab3Scene()
		{
			super();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
		}
		
		override public function loaded():void
		{
			if( _numThiefSpellTargets > 0 || _numSpellTargets > 0 )
			{
				_smokePuffGroup = addChildGroup( new SmokePuffGroup()) as SmokePuffGroup;
				_smokePuffGroup.smokeLoadCompleted.addOnce( smokeReady );
				_smokePuffGroup.initJinnSmoke( this, _hitContainer, _numSpellTargets, _numThiefSpellTargets );
			}
			else
			{
				smokeReady();
			}
		}
		
		public function smokeReady():void
		{
			_events = shellApi.islandEvents as Arab3Events;
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			shellApi.eventTriggered.add( eventTriggered );
			
			super.loaded();
		}
		
		protected function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{	
			
		}
		
		protected function addGenieWaveMotion(entity:Entity, isThief:Boolean = false):Entity
		{
			if(!this.getSystem(WaveMotionSystem))
			{
				this.addSystem(new WaveMotionSystem());
			}
			
			var spatialAddition:SpatialAddition = entity.get(SpatialAddition);
			if(!spatialAddition)
			{
				spatialAddition = new SpatialAddition();
				entity.add(spatialAddition);
			}
			
			var waveMotion:WaveMotion = entity.get(WaveMotion);
			if(!waveMotion)
			{
				waveMotion = new WaveMotion();
				entity.add(waveMotion);
			}
			
			var waveMotionData:WaveMotionData = waveMotion.dataForProperty("y");
			if(!waveMotionData)
			{
				waveMotionData = new WaveMotionData("y", 5, 2, "sin", 0, true);
				waveMotion.add(waveMotionData);
		//		waveMotionData = new WaveMotionData("x", 5, 2, "cos", 0, true);
		//		waveMotion.add(waveMotionData);
			}
			
			_smokePuffGroup.addJinnTailSmoke( entity, isThief );
			return entity;
		}
	}
}