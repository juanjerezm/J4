from dataclasses import dataclass, field
from pathlib import Path

import yaml


@dataclass(frozen=True)
class FuelMap:
    """Mapping entry for a fuel type."""

    id: str
    label: str
    color: str


@dataclass(frozen=True)
class CountryMap:
    """Mapping entry for a country."""

    id: str
    label: str


@dataclass(frozen=True)
class PolicyMap:
    """Mapping entry for a policy type."""

    id: str
    label: str
    marker: str


@dataclass(frozen=True)
class EntityMap:
    """Mapping entry for a generic entity."""

    id: str
    label: str
    color: str


@dataclass(frozen=True)
class OverrideMap:
    """Mapping entry for a scenario override."""

    id: str
    label: str


@dataclass(frozen=True)
class Mappings:
    """Container for all loaded mapping entries and their projection helpers."""

    fuels: list[FuelMap] = field(default_factory=list)
    countries: list[CountryMap] = field(default_factory=list)
    policies: list[PolicyMap] = field(default_factory=list)
    entities: list[EntityMap] = field(default_factory=list)
    overrides: list[OverrideMap] = field(default_factory=list)

    def to_dict(self, mapping: str, key_attr: str, value_attr: str) -> dict:
        """Return a dict {key_attr: value_attr} for entries in the selected mapping."""
        entries = getattr(self, mapping)
        return {getattr(item, key_attr): getattr(item, value_attr) for item in entries}

    def ordered(self, mapping: str, attr: str) -> list:
        """Return attribute values for entries in the selected mapping, preserving source order."""
        entries = getattr(self, mapping)
        return [getattr(item, attr) for item in entries]

    @staticmethod
    def _load_entries(path: Path, entry_cls) -> list:
        """Load mapping entries from a YAML file whose root key matches the filename."""
        with path.open("r", encoding="utf-8") as f:
            raw = yaml.safe_load(f)

        return [entry_cls(**item) for item in raw[path.stem]]

    @classmethod
    def from_dir(cls, mapping_dir: Path) -> "Mappings":
        """Load the standard shared mapping files from a mapping directory."""

        return cls(
            fuels=cls._load_entries(mapping_dir / "fuels.yml", FuelMap),
            countries=cls._load_entries(mapping_dir / "countries.yml", CountryMap),
            policies=cls._load_entries(mapping_dir / "policies.yml", PolicyMap),
            entities=cls._load_entries(mapping_dir / "entities.yml", EntityMap),
            overrides=cls._load_entries(mapping_dir / "overrides.yml", OverrideMap),
        )
