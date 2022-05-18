package game.scenes.lands.shared.ui.panes {
	
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	
	import engine.components.Audio;
	
	import game.scenes.lands.shared.groups.LandUIGroup;
	
	import org.osflash.signals.Signal;
		
	public class LosePane extends LandPane {

		/**
		 * no params. onClosed()
		 * does not trigger for hide(), only for user close.
		 */
		private var onClosed:Signal;

		public function LosePane( pane:DisplayObjectContainer, group:LandUIGroup ) {

			super( pane, group );

			this.makeButton( pane[ "btnTryAgain" ], this.closePane, 2 );

			this.onClosed = new Signal();

		} //

		public function showLose( func:Function=null ):void {
			
			( this.myGroup.landGroup.gameEntity.get( Audio ) as Audio ).playCurrentAction( "lose" );

			this.show();

			if ( func ) {
				this.onClosed.add( func );
			} //

		} //

		private function closePane( e:MouseEvent ):void {

			this.onClosed.dispatch();
			this.hide();

		} //

		override public function destroy():void {

			super.destroy();
			this.onClosed.removeAll();

		} //

	} // class
	
} // package