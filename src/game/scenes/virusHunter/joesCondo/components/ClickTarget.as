package game.scenes.virusHunter.joesCondo.components {

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Interaction;
	
	import game.util.CharUtils;

	// There's no particular reason to make a ClickTarget a component, except that it can be
	// conveniently placed in an entity and subsequently forgotten about.
	public class ClickTarget extends Component {

		static public var player:Entity;

		public var arriveFunc:Function;			// called when player arrives.

		//public var player:Entity;
		//public var minDist:Point;

		public var targetEntity:Entity;

		// If true, moves player to tx,ty instead of targetEntity x/y
		public var useCoordinates:Boolean = false;
		public var tx:Number;
		public var ty:Number;

		public function ClickTarget( target:Entity=null, arriveFunc:Function=null ) {

			super();

			this.targetEntity = target;
			this.arriveFunc = arriveFunc;

			// attempt to hook up the interactions.
			if ( target != null ) {

				var interaction:Interaction = target.get( Interaction );
				if ( interaction != null ) {
					interaction.click.add( this.onClick );
				}

			} //

		} //

		public function onClick( clicked:Entity ):void {

			if ( useCoordinates ) {

				CharUtils.moveToTarget( player, tx, ty, false, arriveFunc );

			} else {

				var display:DisplayObjectContainer = ( targetEntity.get( Display ) as Display ).displayObject;

				CharUtils.moveToTarget( player, display.x, display.y, false, arriveFunc );

			} //

		} //

	} // End ClickTarget

} // End package