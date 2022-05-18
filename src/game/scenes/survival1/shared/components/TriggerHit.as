package game.scenes.survival1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	
	import org.osflash.signals.Signal;

	public class TriggerHit extends Component
	{
		public function TriggerHit( timeline:Timeline = null, validEntities:Vector.<String> = null )
		{
			this.visualTimeline = timeline;
			if( validEntities )
			{
				this.validEntities = validEntities;
			}			
			else
			{
				this.validEntities.push( "player" );
			}
		}
		
		/**
		 * Optional <code>Function</code> to run after animation finishes.
		 * 
		 * Must instantiate it yourself before you can use.
		 */
		public var triggerAfterAnimation:Function;
		
		/**
		 * Optional <code>Signal</code> to fire when player triggers the animation.
		 * 
		 * Must instantiate it yourself before you can use.
		 */
		public var triggered:Signal;
		
		/**
		 * Optional <code>Signal</code> to fire when player stops triggering the animation.
		 * 
		 * Must instantiate it yourself before you can use.
		 */
		
		/**
		 * Optional <code>Vector</code> of valid entity names to trigger this hit.
		 */
		public var validEntities:Vector.<String> = new Vector.<String>;
		public var offTriggered:Signal;
		
		public var active:Boolean = false;
		public var visualTimeline:Timeline;
	}
}