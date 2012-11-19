/*
This module provides various annotations about proteins.

should these methods provide other data, like coordinates of a hit?
*/

module ProteinInfo {

	/*
	A fid is a unique identifier of a feature.
	*/
	typedef string fid;
	
	/*
	A domainId is an identifier of a protein domain or family
	(e.g., COG593, TIGR00362). Most of these are stable identifiers
	that come from external curated libraries, such as COG or InterPro,
	but some are unstable identifiers that come from automated
	analyses like FastBLAST.
	*/
	typedef string domain_id;

	typedef list<string> ec;
	typedef list<string> go;
	typedef list<string> ipr;

	/*
	An operon is represented by a list of fids
	which make up that operon.
	*/
	typedef list<fid> operon;

	/*
	Orthologs are a list of fids which are orthologous to a given fid.
	*/
	typedef list<fid> orthologs;

	typedef list<string> synonyms;
	typedef list<string> domains;

	/*
	fids_to_operons takes as input a list of feature
	ids and returns a mapping of each fid to the operon
	in which it is found 
	*/
	funcdef fids_to_operons (list<fid> fids) returns (mapping<fid, operon>);

	/*
	fids_to_domains takes as input a list of feature ids, and
	returns a mapping of each fid to its domains. (This includes COG,
	even though COG is not part of InterProScan.)
	*/
	funcdef fids_to_domains (list<fid> fids) returns (mapping<fid, domains>);

	funcdef domains_to_fids (domains domain_ids) returns (mapping<domain_id, list<fid>>);

	funcdef fids_to_orthologs (list<fid> fids) returns (mapping<fid, orthologs>);

	/*
	this might be more appropriate for the translation service
	*/
	funcdef fids_to_synonyms (list<fid> fids ) returns (mapping<fid, synonyms>);

	funcdef fids_to_ec (list<fid> fids) returns (mapping<fid,ec>);
	funcdef fids_to_go (list<fid> fids) returns (mapping<fid,go>);
	funcdef fids_to_ipr (list<fid> fids) returns (mapping<fid,ipr>);

};
