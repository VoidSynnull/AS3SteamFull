package game.scenes.lands.shared.tileLib.classes {
	
	
	public class TileLayerProp {

		public var obj:*;
		public var prop:String;

		public var value:*;

		public function TileLayerProp( targObj:*, propName:String, startValue:* ) {

			this.obj = targObj;
			this.prop = propName;

			this.value = startValue;

		} //
		
	} // class
	
} // package