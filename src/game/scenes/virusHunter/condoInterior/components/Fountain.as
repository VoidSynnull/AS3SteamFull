package game.scenes.virusHunter.condoInterior.components {

	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.scenes.virusHunter.condoInterior.classes.Droplet;

	// This code is adapted from the sample fountain I found in ShrinkRay Island, school interior.
	// It is the sort of fountain the artist wanted.

	// Can't see a simple way to do this with Flint because of the nature of the droplet ripple.
	// Sure it can be done, but I'm not very familiar with flint.

	// todo: Bitmap pool, droplet pool.
	public class Fountain extends Component {

		private var RAD_PER_DEG:Number = 180 / Math.PI;

		private var baseAngle:Number = -130*RAD_PER_DEG;

		public var isOn:Boolean = false;

		// Need access to the parent entity to turn the updater off when there are no particles.
		public var myEntity:Entity;

		private var drops:Vector.<Droplet>;

		private var yMax:Number = 90;

		// generic type for all fountain drops.
		private var dropBitmap:BitmapData;

		private var container:Sprite;

		private var rate:int = 2;		// droplet creation rate.
		private var timer:int = 0;

		public function Fountain( container:Sprite, owner:Entity, dropAsset:MovieClip ) {

			this.myEntity = owner;
			this.container = container;

			initBitmap( dropAsset );

			drops = new Vector.<Droplet>();

		} //

		public function turnOn( fountEntity:Entity ):void {

			isOn = true;

			var updater:SimpleUpdater = myEntity.get( SimpleUpdater ) as SimpleUpdater;
			if ( updater == null ) {
				return;
			}
			updater.paused = false;

		} //

		public function turnOff( fountEntity:Entity ):void {

			isOn = false;

		} // end turnOff()

		public function update( time:Number ):void {

			if ( isOn ) {

				if ( ++timer > rate ) {
					timer = 0;
					makeDrop();
				}

			} else {

				if ( drops.length == 0 ) {
					var updater:SimpleUpdater = myEntity.get( SimpleUpdater ) as SimpleUpdater;
					if ( updater == null ) {
						return;
					}
					updater.paused = true;		// stop the update onEnterFrame.
				}

			} // end-if.

			var drop:Droplet;

			for( var i:int = drops.length-1; i >= 0; i-- ) {

				drop = drops[i];

				if ( drop.update() == true ) {

					container.removeChild( drop );
					drops[i] = drops[drops.length-1];
					drops.pop();

				} else if ( drop.mode == Droplet.DROPLET && drop.y > yMax ) {

					drop.makeRipple();

				} // end-if.

			} // end for-loop.

		} // end update()

		private function makeDrop():void {

			var drop:Droplet = new Droplet( dropBitmap );

			drop.x = 0;
			drop.y = 0;
			drop.rotation = -130;

			drop.vx = ( 6 + 2*Math.random() ) * Math.cos( baseAngle );
			drop.vy = ( 14 + 2*Math.random() ) * Math.sin( baseAngle );

			drop.scaleX = drop.scaleY = drop.alpha = 0.5 + 0.5*Math.random();
			drops.push( drop );

			container.addChild( drop );

		} //

		private function initBitmap( dropAsset:MovieClip ):void {

			dropBitmap = new BitmapData( dropAsset.width, dropAsset.height, true, 0 );
			dropBitmap.draw( dropAsset );

		} // End function initBitmap()

	} // End Fountain
	
} // End package