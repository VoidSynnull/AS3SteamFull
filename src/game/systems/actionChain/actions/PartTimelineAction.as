package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.timeline.Timeline;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;

	// Play part timeline
	public class PartTimelineAction extends ActionCommand
	{
		private var partEntity:Entity;
		private var startLabel:String;
		private var waitLabel:String;
		private var stopAtLabel:Boolean = true;
		
		private var _callback:Function;

		/**
		 * Play entity timeline 
		 * @param entity			Player entity
		 * @param part				Part with timeline
		 * @param startLabel		Label to start animation
		 * @param waitLabel			Label to end animation
		 * @param stopAtLabel		Flag to stop at end label
		 */
		public function PartTimelineAction( entity:Entity, part:String, startLabel:String=null, waitLabel:String = "ending", stopAtLabel:Boolean = true )
		{
			this.entity = entity;
			this.partEntity = CharUtils.getPart(entity, part);
			this.startLabel = startLabel;
			this.waitLabel = waitLabel;
			this.stopAtLabel = stopAtLabel;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			var t:Timeline = partEntity.get( Timeline ) as Timeline;

			if (t)
			{
				if ( startLabel != null ) {
					t.gotoAndPlay( startLabel );
				} else {
					t.playing = true;
				}
	
				if ( waitLabel != null ) {
					this._callback = callback;
					t.handleLabel( waitLabel, onLabel, true );
				} else {
					callback();
				}
			}
		}

		private function onLabel():void
		{
			if ( stopAtLabel ) {
				var tl:Timeline = partEntity.get( Timeline );
				tl.playing = false;
			}
			_callback();
		}
	}
}