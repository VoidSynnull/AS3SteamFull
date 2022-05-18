package game.scenes.virusHunter.joesCondo.util {

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;

	public class ClipUtils {

		static public function changeParent( clip:DisplayObject, newParent:DisplayObjectContainer ):void {

			var p:Point = new Point( 0, 0 );
			clip.localToGlobal( p );
			newParent.globalToLocal( p );
			
			newParent.addChild( clip );
			clip.x = p.x;
			clip.y = p.y;

		} //

		static public function makeFadeEntity( parent:DisplayObjectContainer, fadeColor:uint=0x000000 ):Entity {

			var e:Entity = new Entity();

			var s:Sprite = ClipUtils.makeFadeClip( parent, fadeColor );

			e.add( new Display( s ) );
			e.add( new Spatial( 0, 0 ) );

			return e;

		} //

		static public function makeFadeClip( parent:DisplayObjectContainer, fadeColor:uint=0x000000, width:Number=980, height:Number=800 ):Sprite {

			var s:Sprite = new Sprite();
			var g:Graphics = s.graphics;

			g.beginFill( fadeColor, 1 );
			g.drawRect( 0, 0, width, height );

			parent.addChild( s );

			return s;

		} //

	} // End ClipUtils
	
} // End package