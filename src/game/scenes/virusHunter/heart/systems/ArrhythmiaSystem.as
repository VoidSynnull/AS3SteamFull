package game.scenes.virusHunter.heart.systems {

	import com.greensock.TweenLite;
	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.heart.components.Arrhythmia;
	import game.scenes.virusHunter.heart.nodes.ArrhythmiaNode;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.systems.GameSystem;

	public class ArrhythmiaSystem extends GameSystem {

		// beat frequencies of arrhythmia - actually 2*pi*f
		// see youtube walter lewin
		private const freq1:Number = 2*Math.PI;
		private const freq2:Number = 7*Math.PI;

		private var events:VirusHunterEvents;

		private var scene:ShipScene;
		private var pSpatial:Spatial;
		private var sawArrhythmia:Boolean = false;

		public function ArrhythmiaSystem( evts:VirusHunterEvents ) {

			super( ArrhythmiaNode, updateNode, nodeAdded, null );

			this.events = evts;

		} //

		public function updateNode( node:ArrhythmiaNode, time:Number ):void {

			var a:Arrhythmia = node.arrhythmia;
			var anim:MovieClip = node.arrhythmia.anim;

			var beat:Number;			// muscle scale.

			a.timer += time;

			switch ( a.state ) {

				case Arrhythmia.BROKEN:

					if ( node.damageTarget.damage > 0 ) {
						repair( node );
					} else {

						beat = ( Math.sin( this.freq1*a.timer ) + Math.sin( this.freq2*a.timer ) );

						a.muscle.scaleX = anim.scaleY = 1 + 0.01*beat;

						a.nerve1.rotation = a.nerve1Base + 12*beat;
						a.nerve2.rotation = a.nerve2Base + 12*beat;

						var dx:Number = node.spatial.x - this.pSpatial.x;
						var dy:Number = node.spatial.y - this.pSpatial.y;
						if ( dx*dx + dy*dy < 300*300 && !this.sawArrhythmia ) {
							this.sawArrhythmia = true;
							this.scene.playMessage( "heart_secondary", false );
						} //


					} // end-if.

					break;

				case Arrhythmia.FIXED:

					beat = Math.sin( this.freq1*a.timer/2 );
					a.muscle.scaleX = anim.scaleY = 1 + 0.01*beat;

					a.nerve1.rotation = a.nerve1Base + 12*beat;
					a.nerve2.rotation = a.nerve2Base + 12*beat;

					break;

				default:

					// in the process of repairing - bring the nerve rotations back to their base.
					a.nerve1.rotation += ( a.nerve1Base - a.nerve1.rotation ) / 4;
					a.nerve2.rotation += ( a.nerve2Base - a.nerve2.rotation ) / 4;

					break;

			} //

		} //

		private function repair( node:ArrhythmiaNode ):void {

			TweenLite.to( node.arrhythmia.muscle, 1, { scaleX:1, scaleY:1, onComplete:this.fixed, onCompleteParams:[node.entity] } );
			node.arrhythmia.state = Arrhythmia.REPAIRING;

			this.scene.playMessage( "heart_resolved", false );


		} //

		public function fixed( e:Entity ):void {

			var a:Arrhythmia = e.get( Arrhythmia );

			this.group.shellApi.completeEvent( events.FIXED_ARRHYTHMIA );
			a.state = Arrhythmia.FIXED;
			a.timer = 0;

		} //

		public function nodeAdded( node:ArrhythmiaNode ):void {

			this.scene = this.group as ShipScene;
			this.pSpatial = this.group.getEntityById( "player" ).get( Spatial );

			var a:Arrhythmia = node.arrhythmia;

			a.nerve1 = a.anim["nerve1"];
			a.nerve2 = a.anim["nerve2"];
			a.muscle = a.anim["muscle"];

			a.nerve1Base = a.nerve1.rotation;
			a.nerve2Base = a.nerve2.rotation;

			a.timer = 0;

			if ( this.group.shellApi.checkEvent( events.FIXED_ARRHYTHMIA ) ) {

				a.state = Arrhythmia.FIXED;

			} else {

				a.state = Arrhythmia.BROKEN;

			} //

		} //

	} // End ArrhythmiaSystem
	
} // End package