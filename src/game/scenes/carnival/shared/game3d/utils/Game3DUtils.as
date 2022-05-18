package game.scenes.carnival.shared.game3d.utils {

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.carnival.shared.game3d.components.Camera3D;
	import game.scenes.carnival.shared.game3d.components.Frustum;
	import game.scenes.carnival.shared.game3d.components.Hit3D;
	import game.scenes.carnival.shared.game3d.components.Spatial3D;

	public class Game3DUtils {

		static public function makeCamera( display:DisplayObjectContainer ):Entity {

			var e:Entity = new Entity()
				.add( new Display( display ), Display )
				.add( new Camera3D(), Camera3D )
				.add( new Frustum(), Frustum );

			return e;

		} //

		static public function makeObject( display:DisplayObjectContainer, loc:Spatial3D, hit:Hit3D=null ):Entity {

			var e:Entity = new Entity()
				.add( new Display( display ), Display )
				.add( loc, Spatial3D )
				.add( new Spatial( loc.x, loc.y ), Spatial );

			if ( hit != null ) {
				e.add( hit, Hit3D );
			}

			return e;

		} //

	} // End Game3DUtils

} // End package