package com.poptropica.interfaces
{
	public interface IPlatform
	{
		/** Need definition */
		function getInstance(_class:Class, vo:Object = null) : Object;
		/** Need definition */
		function checkClass(_class:Class):Boolean;
	}
}