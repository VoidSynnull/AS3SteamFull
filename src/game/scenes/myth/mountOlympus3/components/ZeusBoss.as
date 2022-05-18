package game.scenes.myth.mountOlympus3.components
{
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.Tween;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.data.TimedEvent;
	import game.util.SceneUtil;
		
	public class ZeusBoss extends Component
	{
		public var health:int = 100;
		public var maxHealth:int = 100;
		public var invincible:Boolean = false;
		public var attackSequences:Vector.<Vector.<String>>;
		public var currentAttackSequence:Vector.<String>;
		public var currentAttackIndex:int = 0;
		public var sequenceLevels:Vector.<int>;
		//public var healthLost:int = 0;
		//public var currentAttackSequenceIndex:int = 0;
		public var lifeBar:Entity;
		
		public var colorFill:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 100, 100, 1, 1, true );
		public var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
		public var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true );	
		
		public var orbEnd:Boolean = false;
		public var activeOrbs:int = 0;
		
		public var maxOrbs:int = 6;
		public var maxBolts:int = 12;
		public var activeBolts:int = 0;
		
		public var orbEntity:Entity;

		public var gust:Gust;
		public var gustSleep:Sleep;
		public var gustDisplay:Display;
		
		public function ZeusBoss( lifeBar:Entity, sequences:Vector.<Vector.<String>>, sequenceLevels:Vector.<int>, maxHealth:Number = 100 )
		{
			this.maxHealth = this.health = maxHealth;
			this.lifeBar = lifeBar;
			this.attackSequences = sequences.slice();
			this.currentAttackSequence = attackSequences.shift();
			this.currentAttackIndex = -1;
			this.sequenceLevels = sequenceLevels.slice();
			hideHealthBar();
		}
		
		/**
		 * Returns the next attack type in current attack sequence.
		 * @param currState
		 * @return 
		 * 
		 */
		public function getNextState():String
		{
			//var nextState:String = ZeusState.DEFEAT;
			//if( health > 0 )
			//{
				currentAttackIndex++;
				if( currentAttackIndex >= currentAttackSequence.length )
				{
					currentAttackIndex = 0;
				}
				return currentAttackSequence[ currentAttackIndex ];
			//}
			//return nextState;
		}
		
		/////////////////////////////// HURT ///////////////////////////////
		
		public function showHealthBar():void
		{
			var display:Display = lifeBar.get( Display );
			var group:Group = lifeBar.get( OwningGroup ).group;
			var tween:Tween = new Tween();
			lifeBar.add( tween );
			var clip:MovieClip = display.displayObject as MovieClip;
			clip.bar.scaleX = health/maxHealth;
			tween.to( display, 0.4, { alpha : 1 });
			SceneUtil.addTimedEvent( group, new TimedEvent( 1.5, 1, hideHealthBar ));
		}
		
		public function hideHealthBar():void
		{
			var display:Display = lifeBar.get( Display );
			var tween:Tween = new Tween();
			lifeBar.add(tween);
			tween.to( display, 0.4, { alpha : 0 });
		}
	}
}