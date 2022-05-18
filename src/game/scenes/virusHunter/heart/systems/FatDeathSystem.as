package game.scenes.virusHunter.heart.systems {
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.heart.components.AngleHit;
	import game.scenes.virusHunter.heart.components.HeartFat;
	import game.scenes.virusHunter.heart.components.SwapDisplay;
	import game.scenes.virusHunter.heart.nodes.FatDeathNode;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.systems.GameSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;

	public class FatDeathSystem extends GameSystem {

		public function FatDeathSystem():void {

			super( FatDeathNode, updateNode, nodeAdded, nodeRemoved );

		} //

		private function updateNode( node:FatDeathNode, time:Number ):void {
		} // updateNode()

		private function nodeAdded( node:FatDeathNode ):void {

			node.timeline.gotoAndPlay( "start" );
			node.timeline.labelReached.add( Command.create( labelReached, node.entity ) );

			var a:Audio = new Audio();
			node.entity.add( a, Audio );
			a.play( SoundManager.EFFECTS_PATH + "squish_10.mp3" );

		} //

		private function labelReached( label:String, entity:Entity ):void {

			if ( label == "wallOpen" ) {

				entity.remove( AngleHit );
				return;

			} else if ( label != "end" ) {
				return;
			}

			var tl:Timeline = entity.get( Timeline ) as Timeline;
			tl.labelReached.removeAll();			// can't remove the command.

			// RE-Bitmap the clip and swap to the second display.
			var oldClip:MovieClip = (entity.get(Display) as Display).displayObject as MovieClip;

			var swap:SwapDisplay = entity.get( SwapDisplay ) as SwapDisplay;
			var sprite:Sprite = swap.saveClip as Sprite;

			var bitmap:Bitmap = sprite.getChildAt( 0 ) as Bitmap;

			var bmd:BitmapData = SimpleUtils.bitmapStageClip( oldClip, true, 0 );

			bitmap.bitmapData = bmd;

			var bnds:Rectangle = oldClip.getBounds( oldClip.parent );
			bitmap.x = bnds.left - oldClip.x;
			bitmap.y = bnds.top - oldClip.y;

			swap.swap();

			// no longer need the timeline or the swap, and this will remove the entity from this system as well.
			//entity.remove( Timeline );

			entity.remove( HeartFat );			// remove from this system.
			entity.remove( SwapDisplay );

		} //

		private function nodeRemoved( node:FatDeathNode ):void {

			node.entity.remove( Audio );

		} //

	} // End class

} // End package