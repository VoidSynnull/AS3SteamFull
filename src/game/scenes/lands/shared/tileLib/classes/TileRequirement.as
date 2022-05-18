package game.scenes.lands.shared.tileLib.classes {

/**
 * Describes a requirement for using a given tileType. You need to have the right amount
 * of the listed resource. For now the only resource is poptanium.
 * 
 */

import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class TileRequirement {

		public var resource:String;
		public var amount:int;

		public var tileType:TileType;

		public function TileRequirement( type:TileType, amount:int, res:String ) {

			this.resource = res;
			this.amount = amount;

			this.tileType = type;

		} //

	} // class

} // package